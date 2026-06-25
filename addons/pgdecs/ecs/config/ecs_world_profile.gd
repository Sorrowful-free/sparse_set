class_name ECSWorldProfile extends Resource

@export var component_registry_strategy: ECSComponentRegistryStrategy
@export var visual_registry_strategy: ECSVisualRegistryStrategy
@export var system_groups: Array[ECSSystemGroupConfig] = []
@export var system_strategies: Array[ECSSystemStrategy] = []

func resolve_system_groups() -> Array[ECSSystemGroupConfig]:
	if system_groups.is_empty():
		return ECSSystemRunGroups.default_group_configs()
	return system_groups

func apply_to_world(world: ECSWorld, visual_host: ECSVisualHost = null) -> void:
	var ecs: ECSManager = world.get_ecs_manager()
	if component_registry_strategy != null and component_registry_strategy.enabled:
		if not ecs.is_schema_registered():
			component_registry_strategy.apply_to(ecs)
	apply_visual_strategy(world, visual_host)

	var configs: Array[ECSSystemGroupConfig] = resolve_system_groups()
	world.install_system_schedule(configs)
	_validate_strategy_groups(configs)

	for strategy: ECSSystemStrategy in system_strategies:
		if strategy == null or not strategy.enabled:
			continue
		var system: ECSSystemBase = strategy.create_system(ecs, world)
		if system == null:
			continue
		system.run_group = strategy.run_group
		world.get_system_runner().add_system(system, strategy.run_group)

func _validate_strategy_groups(configs: Array[ECSSystemGroupConfig]) -> void:
	if not OS.is_debug_build():
		return
	var known: Dictionary = {}
	for config: ECSSystemGroupConfig in configs:
		if config != null and config.enabled:
			known[config.group] = true
	for strategy: ECSSystemStrategy in system_strategies:
		if strategy == null or not strategy.enabled:
			continue
		if not known.has(strategy.run_group):
			push_warning(
				"ECSWorldProfile: strategy run_group '%s' not found in system_groups" % strategy.run_group
			)

func apply_visual_strategy(world: ECSWorld, visual_host: ECSVisualHost = null) -> void:
	if visual_registry_strategy == null or not visual_registry_strategy.enabled:
		return
	var ecs: ECSManager = world.get_ecs_manager()
	var registry: ECSVisualRegistry = visual_registry_strategy.create_registry(ecs, world, visual_host)
	if registry != null:
		world.set_visual_registry(registry)
