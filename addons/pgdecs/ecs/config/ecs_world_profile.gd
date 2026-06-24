class_name ECSWorldProfile extends Resource

@export var component_registry_config: ECSComponentRegistryConfig
@export var visual_registry_config: ECSVisualRegistryConfig
@export var system_strategies: Array[ECSSystemInitStrategy] = []

func apply_to_world(world: ECSWorld) -> void:
	var ecs: ECSManager = world.get_ecs_manager()
	if component_registry_config != null:
		component_registry_config.apply_to(ecs)
	if visual_registry_config != null:
		var context: ECSVisualHostContext = ECSVisualHostContext.from_world(world)
		world.set_visual_registry(visual_registry_config.create_registry(world, context))
	for strategy: ECSSystemInitStrategy in system_strategies:
		if strategy == null or not strategy.enabled:
			continue
		var system: ECSSystemBase = strategy.create_system(ecs, world)
		if system != null:
			world.get_system_runner().add_system(system)
