class_name ECSWorldProfile extends Resource

@export var component_registry_strategy: ECSComponentRegistryStrategy
@export var visual_registry_strategy: ECSVisualRegistryStrategy
@export var system_strategies: Array[ECSSystemStrategy] = []

func apply_to_world(world: ECSWorld, visual_host: ECSVisualHost = null) -> void:
	var ecs: ECSManager = world.get_ecs_manager()
	if component_registry_strategy != null and component_registry_strategy.enabled:
		if not ecs.is_schema_registered():
			component_registry_strategy.apply_to(ecs)
	apply_visual_strategy(world, visual_host)
	for strategy: ECSSystemStrategy in system_strategies:
		if strategy == null or not strategy.enabled:
			continue
		var system: ECSSystemBase = strategy.create_system(ecs, world)
		if system != null:
			world.get_system_runner().add_system(system)

func apply_visual_strategy(world: ECSWorld, visual_host: ECSVisualHost = null) -> void:
	if visual_registry_strategy == null or not visual_registry_strategy.enabled:
		return
	var ecs: ECSManager = world.get_ecs_manager()
	var registry: ECSVisualRegistry = visual_registry_strategy.create_registry(ecs, world, visual_host)
	if registry != null:
		world.set_visual_registry(registry)
