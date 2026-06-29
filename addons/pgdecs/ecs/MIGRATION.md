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

## 2.0 — Bridge layer removed (breaking)

В **PGDECS 2.0** удалён весь bridge-слой. Это осознанный шаг: ядро остаётся SoA + systems + profile; связь с Node/RID/variable data — через **Intent-теги + Resource-реестры** в игровом коде. См. [INTENT_PIPELINE.md](INTENT_PIPELINE.md).

### Удалённые классы

| Категория | Классы |
|-----------|--------|
| Bridge core | `ECSBridgeHost`, `ECSBridgeBackend`, `ECSBridgeRegistry` |
| Systems | `ECSBridgeOrchestratorSystem`, `ECSBridgeSyncSystem` |
| Config | `ECSBridgeRegistryStrategy`, `ECSBridgeBackendStrategy`, `ECSBridgeComponentIds`, `ECSBridgeOrchestratorStrategy`, `ECSBridgeSyncStrategy` |
| ECSWorld API | `get_bridge_registry()`, `set_bridge_registry()` |
| ECSWorldProfile | `bridge_registry_strategy`, `apply_to_world(world, bridge_host)` → `apply_to_world(world)` |

### Быстрая замена

```gdscript
# было (1.x bridge)
profile.bridge_registry_strategy = bridge_strategy
profile.system_strategies = [
    ECSBridgeOrchestratorStrategy.new(),
    ECSBridgeSyncStrategy.new(),
]

# стало (2.0) — игровой код
# Resource-реестры через @export в ECSSystemStrategy (ExampleEcsServices)
# Intent-теги: INTENT_BIND_*, INTENT_RELEASE, INTENT_DESTROY
# Системы: bind → sync → release → destroy sweep
# См. ecs/examples/example_intent_world_profile.gd и INTENT_PIPELINE.md
```

### Таблица: bridge → intent

| 1.x | 2.0 |
|-----|-----|
| `BRIDGE_TYPE` + `BRIDGE_HANDLE` | `*_SLOT` (Int32) на домен |
| `TAG_BRIDGE_PENDING_ACQUIRE` | `INTENT_BIND_*` |
| `TAG_BRIDGE_PENDING_RELEASE` | `INTENT_RELEASE` |
| `ECSBridgeOrchestratorSystem` | `ExampleBindIntentSystem` + `ExampleReleaseIntentSystem` |
| `ECSBridgeSyncSystem` | `ExampleRegistrySyncSystem` (игра) |
| `bridge_registry_strategy` | `@export services: ExampleEcsServices` |

Историческая заметка: в 1.x до bridge существовали `ECSVisual*` / `visual_registry_strategy` — они были удалены ранее.
