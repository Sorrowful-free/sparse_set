# PGDECS

Data-oriented ECS для Godot 4.x (GDScript).

## Правило итерации в системах

| Ситуация | API |
|----------|-----|
| Система **только меняет значения** компонентов и **не создаёт** новых сущностей в этом проходе | **Fast-path:** `get_dense_slots()` + `get_values_buffer()` |
| Система **создаёт/удаляет** сущности, **меняет набор компонентов** или нужен **handle** | **Slot API:** `slot_from_handle(dense[i])` или `get_component(entity_id)` |

Подробно: [ecs/FRAMEWORK.md](ecs/FRAMEWORK.md#ключевое-правило-fast-path-vs-slot-api).

## Быстрый старт

```gdscript
extends ECSWorld

const POSITION_ID: int = 1

func _setup_components() -> void:
    get_ecs_manager().register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
    get_ecs_manager().precache_archetype([POSITION_ID])

func _setup_systems() -> void:
    get_system_runner().add_system(MyMovementSystem.new(get_ecs_manager()))

func _ready() -> void:
    super._ready()
    get_ecs_manager().create_entities(1000, [POSITION_ID])

class MyMovementSystem extends ECSSystemChunkBase:
    func _build_query() -> ECSQuery:
        return ECSQueryBuilder.new().with_component(1).build(get_ecs_manager())

    func process_chunk(chunk: ECSQueryChunk, delta: float) -> void:
        var pos_chunk = chunk.get_component_chunk(1) as ECSComponentVector2ArrayChunk
        var slots: PackedInt32Array = chunk.get_dense_slots()
        var buf: PackedVector2Array = pos_chunk.get_values_buffer()
        for i in range(chunk.get_entity_count()):
            var slot: int = slots[i]
            pos_chunk.set_value_at_slot(slot, buf[slot] + Vector2(delta, 0))
```

## API

**Внешний (удобный):** типизированный `Array[int]`, `PackedInt64Array` создаётся внутри.

- `create_entity([POSITION_ID, HEALTH_ID])`
- `create_entities(count, [POSITION_ID])`
- `destroy_entities([id1, id2])`
- `precache_archetype([POSITION_ID, HEALTH_ID])`
- `prepare_archetype([...])` → нормализованный `PackedInt64Array` для hot-path

**Hot path:** переиспользуйте результат `prepare_archetype` с `*_packed`:

```gdscript
var PLAYER := ecs.prepare_archetype([POSITION_ID, HEALTH_ID])
ecs.create_entities_packed(100, player_arch)
ecs.destroy_entities_packed(survivor_ids)
```

**ECSQueryBuilder** — одиночные и пакетные фильтры:

```gdscript
ECSQueryBuilder.new()
    .with_components([POSITION_ID, HEALTH_ID])
    .without_components([TAG_ID])
    .build(ecs)
```

**ECSCommandBuffer** — тот же двухслойный API, что у менеджера:

```gdscript
buf.create_entity([POSITION_ID])
buf.create_entity_packed(player_arch)
buf.destroy_entities([id_a, id_b])
buf.destroy_entities_packed(batch_ids)
```

## Документация

- **[FRAMEWORK.md](ecs/FRAMEWORK.md)** — полное руководство по фреймворку (API, системы, query, правило fast-path)
- [DESIGN.md](ecs/DESIGN.md) — архитектурные решения, чанки, membership
- [PERFORMANCE.md](ecs/PERFORMANCE.md) — hot path, бенчмарки, change detection
- [OBJECT_COMPONENTS.md](ecs/OBJECT_COMPONENTS.md) — Node/String через реестры
- [MIGRATION.md](ecs/MIGRATION.md) — внешний API (`Array[int]`) и hot path (`*_packed`)
- [NAMING.md](ecs/NAMING.md) — префиксы и имена классов
- [agent_handoff/](ecs/agent_handoff/README.md) — шаблоны для Composer (батчи, gates, self-check)
- [tests/README.md](ecs/tests/README.md) — юнит- и perf-тесты

## Тесты

```powershell
& "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path . --script res://addons/pgdecs/ecs/tests/run_unit_tests_headless.gd
& "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path . --script res://addons/pgdecs/ecs/tests/run_performance_tests_headless.gd
```

## Demo

См. [ecs/examples/demo_world.gd](ecs/examples/demo_world.gd) — bootstrap 1000 сущностей без сцены.
