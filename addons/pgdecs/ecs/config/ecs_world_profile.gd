class_name ECSWorldProfile extends Resource

@export var component_registry_strategy: ECSComponentRegistryStrategy
@export var visual_registry_strategies: Array[ECSVisualRegistryStrategy] = []
@export var system_strategies: Array[ECSSystemStrategy] = []

func apply_to_world(world: ECSWorld, visual_host: ECSVisualHost = null) -> void:
	var ecs: ECSManager = world.get_ecs_manager()
	if component_registry_strategy != null and component_registry_strategy.enabled:
		component_registry_strategy.apply_to(ecs)
	for strategy: ECSVisualRegistryStrategy in visual_registry_strategies:
		if strategy == null or not strategy.enabled:
			continue
		var registry: ECSVisualRegistry = strategy.create_registry(ecs, world, visual_host)
		if registry != null:
			world.set_visual_registry(registry)
			break
	for strategy: ECSSystemStrategy in system_strategies:
		if strategy == null or not strategy.enabled:
			continue
		var system: ECSSystemBase = strategy.create_system(ecs, world)
		if system != null:
			world.get_system_runner().add_system(system)
