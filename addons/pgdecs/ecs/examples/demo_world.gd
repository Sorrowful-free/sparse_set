extends ECSWorld
class_name ECSDemoWorld

const POSITION_ID: int = 1
const VELOCITY_ID: int = 2

func bootstrap(entity_count: int = 1000) -> void:
	_ecs_manager = ECSManager.new()
	_system_runner = ECSSystemRunner.new()
	_setup_components()
	_setup_systems()
	_ecs_manager.create_entities_packed(entity_count, PackedInt64Array([POSITION_ID, VELOCITY_ID]))

func _setup_components() -> void:
	_ecs_manager.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	_ecs_manager.register_component(VELOCITY_ID, TYPE_PACKED_FLOAT32_ARRAY)
	_ecs_manager.precache_archetype_packed(PackedInt64Array([POSITION_ID, VELOCITY_ID]))

func _setup_systems() -> void:
	pass
