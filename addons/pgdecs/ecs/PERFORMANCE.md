# Производительность PGDECS

PGDECS оптимизирует **layout данных и итерацию** в GDScript. Это не замена C++/Rust ECS: интерпретатор, GC и отсутствие SIMD задают потолок.

Полное руководство и **правило fast-path vs slot API**: [FRAMEWORK.md](FRAMEWORK.md).

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
| Fast-path iterate | `get_dense_slots()` + `get_values_buffer()` — ~12× быстрее legacy slot API |
| Архетипы | Единый hash-кэш (info + id), `precache_archetype_packed()`, очистка при evict |
| Query | Кэш подходящих архетипов; `begin_chunk_run` + index loop без Callable в системном раннере |
| Query (legacy) | `get_chunks()` / `collect_chunks(out, true)` — pooled views; `collect_chunks(out, false)` — независимые snapshot |
| Handles | Generational id — безопасный реюз без stale access через `has_component` |
| Destroy | Archetype batch remove по chunk; component `remove_entities_batch` |
| Component batch | Hybrid bucketing: sparse при плотном chunk range, compact при разреженных index |
| Command buffer | Coalescing перед `execute()`: cancel create+destroy, add+remove, merge destroys |
| Change detection | Монотонные версии на archetype/component chunk; opt-in `change_detection` в системах |
| BitMask | Bounds-guard, стабильный hash без временных `slice` в `bit_hash()` |
| Transitions | Кэш `(old_archetype_hash, component_id)` для add/remove |
| Chunk run buffer | Один пул `ECSQueryChunk` на query; системы без Callable в main/WTP path |
| WTP systems | `run_chunks_for_system` — прямой `process_chunk`; `run_chunks(Callable)` только бенчмарки |

## PGDECS vs GECS (как читать бенчмарки)

Запуск side-by-side:

```powershell
& godot --headless --path . --main-scene res://addons/gecs/tests/run_compare_frameworks_headless.tscn
```

В конце лога — `--- Compare summary ---`. Имена метрик — общий контракт `addons/gecs/tests/compare_metric_names.gd`; в pgdecs они продублированы в [`tests/performance/ecs_benchmark.gd`](tests/performance/ecs_benchmark.gd), чтобы перф-тесты парсились без аддона gecs.

| Пара | Честно? | Типично (25k, одна сессия) |
|------|---------|----------------------------|
| PGDECS **FAST** vs GECS **column iterate** | **Да** — оба hot-path SoA | PGDECS **~10×** быстрее (~0.21 s vs ~2.3 s) |
| PGDECS **slot API** vs GECS column | **Нет** — разный API | GECS ~1.1× быстрее |
| WTP e+c | **Нет** — разная гранулярность | GECS ~9× быстрее (1 архетип vs ~98 чанков / ~13 tasks) |
| create_entity / batch spawn | — | PGDECS **~10–16×** быстрее |
| change_detection hot-chunks ON | Разный дизайн | PGDECS сильно быстрее (skip-clean чанков) |

**Для агентов:** не сравнивать PGDECS slot API с GECS column как «кто лучше ECS»; fair-пара — FAST vs column. WTP GECS выигрывает на лёгкой работе из‑за overhead group tasks, не из‑за layout.

Сводка и multirun: [`addons/gecs/tests/reports/compare_pgdecs_gecs.md`](../../gecs/tests/reports/compare_pgdecs_gecs.md) (требует аддон gecs).

## Рекомендации hot path

### Правило fast-path vs slot API (обязательное для систем)

| Условие в `process_chunk` | API |
|---|---|
| Только чтение/запись **значений** компонентов; **нет** create/destroy/add/remove в этом проходе | **Fast-path** |
| Create/destroy сущностей, add/remove компонентов, нужен **entity handle** | **Slot API** через handle |

**Fast-path** (~12× быстрее legacy на iterate entities+components при iterations=25000):

```gdscript
var slots := chunk.get_dense_slots()
var count := chunk.get_entity_count()
var pos_buf := pos_chunk.get_values_buffer()
var health_buf := health_chunk.get_values_buffer()
for i in range(count):
    var slot := slots[i]
    var p := pos_buf[slot]
    pos_chunk.set_value_at_slot(slot, p + Vector2(1, 0))  # set_value_at_slot — для change_detection
```

**Slot API** (структурные операции, command buffer, `get_component(entity_id)`):

```gdscript
var dense := chunk.get_dense_entities()
for i in range(chunk.get_entity_count()):
    var handle := dense[i]
    var slot := ECSEntityIdsUtils.slot_from_handle(handle)
    pos_chunk.set_value_at_slot(slot, ...)
    get_command_buffer().destroy_entity(handle)
```

Запись напрямую в `get_values_buffer()[slot]` без `set_value_at_slot` обходит инкремент `_value_version` — не используйте при `change_detection = true`.

### WTP tuning (per-system)

[`ECSChunkParallelSettings`](systems/ecs_chunk_parallel_settings.gd): `chunks_per_task` (default 8), `min_parallel_tasks` (default 2), `parallel_mode` AUTO|FORCE.

- **AUTO** — лёгкие системы; при малом числе задач — main thread.
- **FORCE** — тяжёлый `process_chunk`; `task_count = min(CPU, chunk_count)`.

В profile: [`ECSChunkSystemStrategy`](config/ecs_chunk_system_strategy.gd) с `@export parallel_settings`.

Median perf (5 runs, iterations=25000): legacy **3.38 s**, FAST **0.29 s** — см. `tests/reports/multirun_dense_fast_verify/`.

### Общие рекомендации

1. **Chunk iteration** — системы: `ECSSystemChunkBase` + `process_chunk` (раннер: `begin_chunk_run`, без Callable). Скрипты: `for_each_chunk`. WTP: `use_worker_pool` + `parallel_settings` → `run_chunks_for_system`; при `task_count == 0` — main-loop без dispatch. `ECSChunkWorkerDispatch.run_chunks(Callable)` — только бенчмарки.
2. **Dense iteration** — `chunk.get_entity_count()` + fast-path или `get_dense_entities()` + slot API.
3. **Slot API** — `get_value_at_slot` / `set_value_at_slot` в component chunk (без lookup handle внутри get).
4. **`precache_archetype_packed()`** — до массового spawn с известным набором компонентов.
5. **Батчи** — `create_entities_packed()`, `destroy_entities()`, command buffer с coalescing.
6. **Не вызывать** `get_entity_ids()` каждый кадр, если достаточно chunk-system с dense loop.
7. **Change detection** — `system.change_detection = true` для skip-clean неизменённых чанков (steady-state системы).

## Change detection (версии чанков)

Две независимые монотонные версии:

| Версия | Где | Инкремент |
|--------|-----|-----------|
| Структурная | `ECSArchetypeChunk` | `add_entity` / `remove_entity` / `clear` (реальные мутации) |
| Значений | `ECSComponentBaseArrayChunk` | `set_value_at_slot`, add/remove/batch/clear |

Проброс через `ECSQueryChunk.get_structural_version()` и `get_component_version(component_id)`.

В `ECSSystemChunkBase` при `change_detection == true` система хранит last-seen `[struct_ver, val_ver(c0), ...]` per archetype-chunk (ключ — `instance_id`) и вызывает `process_chunk` только для изменившихся чанков. Работает на main thread и с `use_worker_pool`.

**Стоимость:** один `_value_version += 1` на вызов мутирующего API компонента (не на элемент в батче). При `change_detection == false` оверхеда на итерацию нет.

**Change detection:** при `change_detection=true` после каждого `update` чанки, исчезнувшие из query, удаляются из `_chunk_seen`.

### Два режима бенчмарка (iterations=25000)

| Сценарий | Что моделирует | change_detection ON | OFF | Вывод |
|---|---|---:|---:|---|
| **steady** | Ничего не меняется | **0.052 s** (med) | — | Потолок оверхеда: только проверка версий |
| **scattered** | ~2% случайных записей/кадр по всему миру | 1.960 s | 2.004 s | ≈паритет — грязными становятся многие чанки |
| **hot-chunks** | 2 локальных чанка × 32 записи/кадр | **0.123 s** | 1.937 s | **~16× быстрее** — типичный игровой паттерн |

Median по 5 прогонам: `tests/reports/multirun_dirty_hot/` (скрипт `run_change_detection_hot_perf_headless.gd`).

**В реальном приложении** изменения почти никогда не равномерны: движется группа сущностей (игрок, снаряды, AI-зона), остальной мир статичен. `change_detection` экономит стоимость `process_chunk` на чистых чанках; steady/scattered — граничные случаи (оверхед vs «всё горячее»).

```gdscript
# Включать, когда большинство чанков большую часть кадров чистые:
system.change_detection = true
```

```gdscript
class MySystem extends ECSSystemChunkBase:
    func _init(ecs: ECSManager) -> void:
        super(ecs)
        change_detection = true
```

## Пример итерации (система, fast-path)

Система только меняет значения — без create/destroy в `process_chunk`:

```gdscript
func process_chunk(chunk: ECSQueryChunk, _delta: float) -> void:
    var pos_chunk := chunk.get_component_chunk(POSITION_ID) as ECSComponentVector2ArrayChunk
    var slots := chunk.get_dense_slots()
    var buf := pos_chunk.get_values_buffer()
    for i in range(chunk.get_entity_count()):
        var slot := slots[i]
        pos_chunk.set_value_at_slot(slot, buf[slot] + Vector2(1, 0))
```

## Пример итерации (slot API)

Нужен handle (command buffer, destroy, add_component):

```gdscript
func process_chunk(chunk: ECSQueryChunk, _delta: float) -> void:
    var pos_chunk := chunk.get_component_chunk(POSITION_ID) as ECSComponentVector2ArrayChunk
    var dense := chunk.get_dense_entities()
    for i in range(chunk.get_entity_count()):
        var handle := dense[i]
        var slot := ECSEntityIdsUtils.slot_from_handle(handle)
        pos_chunk.set_value_at_slot(slot, pos_chunk.get_value_at_slot(slot) + Vector2(1, 0))
```

## Пример итерации (система, раннер)

`ECSSystemChunkBase` вызывает `process_chunk` через `begin_chunk_run` — без Callable на каждый чанк. При WTP и `task_count > 0` — `run_chunks_for_system` (виртуальный вызов, не lambda):

```gdscript
# Внутри ECSSystemChunkBase.update (main thread):
var run_count := _query.begin_chunk_run()
for i in range(run_count):
    process_chunk(_query.get_chunk_at_run_index(i), delta)
```

## Пример `for_each_chunk` (скрипты / тесты)

```gdscript
query.for_each_chunk(func(chunk: ECSQueryChunk) -> void:
    process_chunk(chunk, delta)
)
```

`get_entity_ids()` и `get_chunks()` делегируют pooled run; для chunk-систем предпочтителен `begin_chunk_run` или наследование `ECSSystemChunkBase`.

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
| `query.for_each_chunk iterate` | hot path chunk-callback (Callable на границе) |
| `query iterate e+c begin_chunk_run main` | index loop без Callable (как `ECSSystemChunkBase`) |
| `query iterate entities+components` | entity-level loop + get/set компонентов (slot API) |
| `query iterate entities+components FAST` | fast-path: `get_dense_slots()` + `get_values_buffer()` |
| `query iterate e+c WorkerThreadPool` | slot API через `ECSChunkWorkerDispatch` (AUTO, chunks_per_task=8) |
| `query.for_each_chunk WorkerThreadPool` | chunk count через `ECSChunkWorkerDispatch` (AUTO) |
| `add/remove_component` | N пар add+remove (archetype transition) |
| `command_buffer execute` | 1000× `create_entity` + execute |
| `command_buffer coalescing frame` | 5000 raw-команд с coalescing (см. ниже) |
| `system change_detection steady` | 100× update с `change_detection` без записей в мир |
| `system change_detection scattered ON/OFF` | ~2% случайных записей/кадр (размазанные изменения) |
| `system change_detection hot-chunks ON/OFF` | 2 локальных чанка/кадр (неравномерная активность) |

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
