extends ECSWorld
class_name ECSDemoWorld

const POSITION_ID: int = 1
const VELOCITY_ID: int = 2

func build_profile() -> ECSWorldProfile:
	var world_profile := ECSWorldProfile.new()
	world_profile.component_registry_strategy = ExampleComponentRegistryStrategy.create_demo()
	world_profile.system_strategies = [DemoMovementStrategy.new()]
	return world_profile

func bootstrap(entity_count: int = 1000, initial_velocity: float = 1.0) -> void:
	if profile == null:
		profile = build_profile()
	if not is_profile_applied():
		apply_profile(profile)
	var ecs: ECSManager = get_ecs_manager()
	var mover_arch: PackedInt64Array = ecs.prepare_archetype([POSITION_ID, VELOCITY_ID])
	var entity_ids: PackedInt64Array = ecs.create_entities_packed(entity_count, mover_arch)
	if initial_velocity != 0.0:
		var velocity: ECSComponentFloat32Array = ecs.get_component_array(VELOCITY_ID)
		for entity_id: int in entity_ids:
			velocity.set_component(entity_id, initial_velocity)
