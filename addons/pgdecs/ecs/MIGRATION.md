# Migration Guide (Breaking API)

Этот документ покрывает API создания сущностей в `ECSManager`.

## Текущая модель (два слоя)

| Слой | Методы | Когда |
|---|---|---|
| **Внешний** | `create_entity`, `create_entities`, `destroy_entities`, `precache_archetype` (`Array[int]`) | Игровой код, setup, разовые вызовы |
| **Hot path** | `create_entity_packed`, `create_entities_packed`, `destroy_entities_packed`, `precache_archetype_packed` | Циклы, батчи, command buffer execute |
| **Предефайн** | `prepare_archetype([...])` → `PackedInt64Array` | Один раз в `_setup`, дальше `*_packed` |

## Быстрые замены

```gdscript
# Удобный внешний API
var e := ecs.create_entity([POSITION_ID, HEALTH_ID])
var ids := ecs.create_entities(1000, [POSITION_ID])
ecs.destroy_entities([id_a, id_b])
ecs.precache_archetype([POSITION_ID, HEALTH_ID])

# Hot path (без аллокации Array на каждый вызов)
var player_arch := ecs.prepare_archetype([POSITION_ID, HEALTH_ID])
ecs.create_entity_packed(player_arch)
ecs.create_entities_packed(100, player_arch)
ecs.destroy_entities_packed(survivor_ids)
```

## Историческая заметка

Ранее существовали varargs `create_entity(a, b, c)` — заменены на явный `Array[int]` + внутренний `PackedInt64Array` для предсказуемости типов и hot path.

## Safety refactor (архетипы, query, reset)

| Изменение | Детали |
|---|---|
| Ключи архетипов | Реестр по `PackedInt64Array` component ids, не по `bit_hash()` |
| `ECSManager.reset()` | Уничтожает все сущности и архетипы; `register_component` сохраняется |
| `auto_gc_archetypes` | По умолчанию `true`: GC один раз в конце кадра `ECSWorld._process` |
| `flush_archetype_gc()` | Ручной сброс отложенного GC (бенчмарки без раннера) |
| `get_chunks()` | Pooled views текущего run — **не** кэшировать между вызовами |
| `for_each_chunk()` | Тот же пул; Callable на границе callback — для скриптов/тестов |
| `begin_chunk_run()` | Предпочтительно в ручной итерации; системы используют через `ECSSystemChunkBase` |
| `get_entity_archetype()` | Не кэшировать `ECSArchetype` между кадрами после destroy/GC |

## Visual registry (profile)

```gdscript
# было
profile.visual_registry_strategies = [UnitsVisualStrategy.new()]

# стало
profile.visual_registry_strategy = UnitsVisualStrategy.new()
```

Несколько backends — один `create_registry`, несколько `registry.register_backend(...)`. Удалены `absorb()` и массив strategies.
