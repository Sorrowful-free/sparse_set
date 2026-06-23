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
| Доступ к данным | index→slot O(1) сохранён |
| Архетипы | Кэш по hash маски, `precache_archetype()` |
| Query | Кэш подходящих архетипов, пул `ECSQueryChunk` в `get_chunks()` |
| Handles | Generational id — безопасный реюз без stale access через `has_component` |
| Destroy | Итерация только по `component_ids` архетипа, батч `remove_entities_batch` |
| BitMask | Bounds-guard, стабильный hash |

## Рекомендации hot path

1. **Dense iteration** — `chunk.get_dense_entities()` + `chunk.get_entity_count()`.
2. **Slot API** — `get_value_at_slot` / `set_value_at_slot` в component chunk (без lookup handle внутри get).
3. **`precache_archetype()`** — до массового spawn с известным набором компонентов.
4. **Батчи** — `create_entities()`, `destroy_entities()`, command buffer.
5. **Не вызывать** `get_entity_ids()` каждый кадр, если достаточно chunk-system с dense loop.

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

## Устаревшие проблемы (исправлено)

- `_entities_ids.erase` / `find` в component arrays — списки сущностей на уровне компонента убраны.
- Двойное членство archetype + component `_entity_ids` — только archetype.
- Scan 256 слотов в `get_entity_count()` query chunk — dense `_count`.
- `get_or_create_chunk` с одним чанком — расширение до `chunk_index` как в archetype.

## Бенчмарки

`ecs/tests/performance/ecs_benchmark.gd` — create/destroy, query, dense chunk iteration. Запуск через `run_performance_tests.gd` в редакторе.

## Честные ожидания

Для десятков тысяч сущностей с простой логикой PGDECS в GDScript приемлем. Для сотен тысяч с тяжёлой логикой на сущность — рассмотреть GDExtension/C# или вынести hot loop в нативный код. PGDECS даёт предсказуемый SoA layout и O(alive) итерацию в рамках GDScript.
