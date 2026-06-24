# PGDECS

Data-oriented ECS для Godot 4.x (GDScript).

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
        var count: int = chunk.get_entity_count()
        var dense: PackedInt64Array = chunk.get_dense_entities()
        for i in range(count):
            var slot: int = ECSEntityIdsUtils.slot_from_handle(dense[i])
            var p: Vector2 = pos_chunk.get_value_at_slot(slot)
            pos_chunk.set_value_at_slot(slot, p + Vector2(delta, 0))
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

- [DESIGN.md](ecs/DESIGN.md) — архитектура, чанки, membership
- [PERFORMANCE.md](ecs/PERFORMANCE.md) — hot path, ограничения GDScript
- [OBJECT_COMPONENTS.md](ecs/OBJECT_COMPONENTS.md) — Node/String через реестры
- [MIGRATION.md](ecs/MIGRATION.md) — внешний API (`Array[int]`) и hot path (`*_packed`)
- [agent_handoff/](ecs/agent_handoff/README.md) — шаблоны для Composer (батчи, gates, self-check)
- [tests/README.md](ecs/tests/README.md) — юнит- и perf-тесты

## Тесты

```powershell
& "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path . --script res://addons/pgdecs/ecs/tests/run_unit_tests_headless.gd
& "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path . --script res://addons/pgdecs/ecs/tests/run_performance_tests_headless.gd
```

## Demo

См. [ecs/examples/demo_world.gd](ecs/examples/demo_world.gd) — bootstrap 1000 сущностей без сцены.
