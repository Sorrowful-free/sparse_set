# PGDECS

Data-oriented ECS для Godot 4.x (GDScript).

## Быстрый старт

```gdscript
extends ECSWorld

const POSITION_ID: int = 1

func _setup_components() -> void:
    get_ecs_manager().register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)

func _setup_systems() -> void:
    get_system_runner().add_system(MyMovementSystem.new(get_ecs_manager()))

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

## Документация

- [DESIGN.md](ecs/DESIGN.md) — архитектура, чанки, membership
- [PERFORMANCE.md](ecs/PERFORMANCE.md) — hot path, ограничения GDScript
- [OBJECT_COMPONENTS.md](ecs/OBJECT_COMPONENTS.md) — Node/String через реестры
- [tests/README.md](ecs/tests/README.md) — юнит- и perf-тесты

## Тесты

```powershell
& "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path . --script res://addons/pgdecs/ecs/tests/run_unit_tests_headless.gd
```

## Demo

См. [ecs/examples/demo_world.gd](ecs/examples/demo_world.gd) — bootstrap 1000 сущностей без сцены.
