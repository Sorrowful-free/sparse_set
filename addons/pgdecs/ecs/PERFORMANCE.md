# Производительность PGDECS

PGDECS оптимизирует **layout данных и итерацию** в GDScript. Это не замена C++/Rust ECS: интерпретатор, GC и отсутствие SIMD задают потолок.

## Ограничения GDScript

- **RefCounted** — аллокации при `new()` (QueryChunk, временные объекты). Горячий путь систем должен работать с packed-массивами и slot API.
- **WorkerThreadPool** + GDScript в headless/редакторе — ограниченная выгода; chunk-системы предпочтительно в main thread без shared mutable state.
- **Нет SIMD** — векторные операции по одному элементу за итерацию.
- **Packed arrays** — быстрый доступ по индексу, но `erase`/сдвиги O(n); избегать в hot path.

## Сделанные оптимизации

| Область | Решение |
|---------|---------|
| Итерация query/system | Dense sidecar в `ECSArchetypeChunk`: O(alive) на чанк, не O(256) |
| `get_entity_count()` | O(1) из `_count`, без скана слотов |
| Членство | Только archetype — нет дубля `_entity_ids` на каждый компонент (−256×int64 на чанк×тип) |
| Remove в чанке | `slot -> dense_index` sidecar: swap-remove за O(1) без линейного поиска |
| Доступ к данным | index→slot O(1) сохранён |
| Архетипы | Кэш по hash маски, `precache_archetype_packed()` |
| Query | Кэш подходящих архетипов; `for_each_chunk()` без `Array` у вызывающего |
| Query (legacy) | `get_chunks()` — пул `ECSQueryChunk`, предпочтительно `for_each_chunk()` |
| Handles | Generational id — безопасный реюз без stale access через `has_component` |
| Destroy | Итерация только по `component_ids` архетипа, батч `remove_entities_batch` |
| Component batch | Counting-sort группировка по chunk, single-chunk fast-path |
| Command buffer | Coalescing перед `execute()`: cancel create+destroy, add+remove, merge destroys |
| BitMask | Bounds-guard, стабильный hash без временных `slice` в `bit_hash()` |
| Transitions | Кэш `(old_archetype_hash, component_id)` для add/remove |

## Рекомендации hot path

1. **Chunk iteration** — `query.for_each_chunk(callback)` вместо `get_chunks()` + цикл по `Array` (main thread).
2. **Dense iteration** — `chunk.get_dense_entities()` + `chunk.get_entity_count()`.
3. **Slot API** — `get_value_at_slot` / `set_value_at_slot` в component chunk (без lookup handle внутри get).
4. **`precache_archetype_packed()`** — до массового spawn с известным набором компонентов.
5. **Батчи** — `create_entities_packed()`, `destroy_entities()`, command buffer с coalescing.
6. **Не вызывать** `get_entity_ids()` каждый кадр, если достаточно chunk-system с dense loop.

## Пример итерации (система)

```gdscript
func process_chunk(chunk: ECSQueryChunk, _delta: float) -> void:
    var pos_chunk := chunk.get_component_chunk(POSITION_ID) as ECSComponentVector2ArrayChunk
    var count: int = chunk.get_entity_count()
    var dense: PackedInt64Array = chunk.get_dense_entities()
    for i in range(count):
        var slot: int = ECSEntityIdsUtils.slot_from_handle(dense[i])
        pos_chunk.set_value_at_slot(slot, pos_chunk.get_value_at_slot(slot) + Vector2(1, 0))
```

## Пример `for_each_chunk`

```gdscript
query.for_each_chunk(func(chunk: ECSQueryChunk) -> void:
    process_chunk(chunk, delta)
)
```

`get_entity_ids()` и `get_chunks()` внутри используют тот же путь; для горячих систем предпочтителен прямой callback.

## Устаревшие проблемы (исправлено)

- `_entities_ids.erase` / `find` в component arrays — списки сущностей на уровне компонента убраны.
- Двойное членство archetype + component `_entity_ids` — только archetype.
- Scan 256 слотов в `get_entity_count()` query chunk — dense `_count`.
- `get_or_create_chunk` с одним чанком — расширение до `chunk_index` как в archetype.

## Бенчмарки

Источник: [`tests/performance/ecs_benchmark.gd`](tests/performance/ecs_benchmark.gd).

| Метрика | Что измеряет |
|---------|----------------|
| `create_entity` | N одиночных create |
| `destroy_entity` | N одиночных destroy |
| `create_entities batch` | несколько батчей `create_entities_packed` |
| `destroy_entities batch` | один батч destroy на N сущностей |
| `query.get_entity_ids` | сбор id при большом мире |
| `query.for_each_chunk iterate` | hot path chunk-callback без `Array` у вызывающего |
| `query iterate entities+components` | entity-level loop + get/set компонентов |
| `query iterate e+c WorkerThreadPool` | то же через WTP |
| `query chunks WorkerThreadPool` | chunk iteration через WTP |
| `add/remove_component` | N пар add+remove (archetype transition) |
| `command_buffer execute` | 1000× `create_entity` + execute |
| `command_buffer coalescing frame` | 5000 raw-команд с coalescing (см. ниже) |

### Coalescing frame

При `iterations=25000`: 1000 циклов × 5 команд (create+destroy temp, add+remove, destroy survivor). После coalesce — фактически batch destroy. Для оценки command buffer coalescing, не чистого create-path.

### Запуск

- Редактор: `tests/run_performance_tests.gd` (EditorScript)
- Headless: `tests/run_performance_tests_headless.gd` — три шкалы: 5000 / 15000 / 25000
- Composer gate (опционально): `PGDECS_RUN_PERF=1` + `run_composer_gates_headless.gd`

### Multirun и агрегация

Сохраняйте серии прогонов в `tests/reports/multirun_<label>/run_1.log` … `run_5.log`.  
Сравнивайте **median по ≥5 прогонам в одной сессии**; межсессионный шум может давать ложные ±15% на всех метриках.

Агрегатор (PowerShell, из `tests/reports/`):

```powershell
.\aggregate_multirun.ps1 -Directory multirun_foreach_rerun
.\aggregate_multirun.ps1 -Directory multirun_coalesce_bench -Markdown
.\aggregate_multirun.ps1 -Directory multirun_foreach_rerun -CompareDirectory multirun_rerun -Markdown
```

Сводный отчёт по этапам оптимизации: [`tests/reports/post_handoff_perf.md`](tests/reports/post_handoff_perf.md).

## Честные ожидания

Для десятков тысяч сущностей с простой логикой PGDECS в GDScript приемлем. Для сотен тысяч с тяжёлой логикой на сущность — рассмотреть GDExtension/C# или вынести hot loop в нативный код. PGDECS даёт предсказуемый SoA layout и O(alive) итерацию в рамках GDScript.
