extends ECSWorld
class_name ECSDemoWorld

const POSITION_ID: int = 1
const VELOCITY_ID: int = 2

func build_profile() -> ECSWorldProfile:
	var world_profile := ECSWorldProfile.new()
	world_profile.component_registry_strategy = ExampleComponentRegistryStrategy.create_demo()
	return world_profile

func bootstrap(entity_count: int = 1000) -> void:
	if profile == null:
		profile = build_profile()
	if not is_profile_applied():
		apply_profile(profile)
	var ecs: ECSManager = get_ecs_manager()
	var mover_arch: PackedInt64Array = ecs.prepare_archetype([POSITION_ID, VELOCITY_ID])
	ecs.create_entities_packed(entity_count, mover_arch)
