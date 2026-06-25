class_name ECSBridgeRegistryStrategy extends Resource

## Установка bridge-слоя: component ids + backends. Аналог [ECSComponentRegistryStrategy] для bridge.
@export var enabled: bool = true
@export var component_ids: ECSBridgeComponentIds
@export var backend_strategies: Array[ECSBridgeBackendStrategy] = []

func apply_to(world: ECSWorld, host: ECSBridgeHost) -> ECSBridgeRegistry:
	if not enabled:
		return null
	if component_ids == null:
		return null
	if host == null:
		return null
	if backend_strategies.is_empty():
		return null
	host.refresh_slots()
	var ecs: ECSManager = world.get_ecs_manager()
	var registry := ECSBridgeRegistry.new()
	registry.apply_component_ids(component_ids)
	for strategy: ECSBridgeBackendStrategy in backend_strategies:
		if strategy == null or not strategy.enabled:
			continue
		var backend: ECSBridgeBackend = strategy.create_backend(host, ecs, world)
		if backend != null:
			registry.register_backend(strategy.bridge_type, backend)
	world.set_bridge_registry(registry)
	return registry

func validate_sync_pairing(system_strategies: Array[ECSSystemStrategy]) -> void:
	if not OS.is_debug_build():
		return
	var backend_types: Dictionary = {}
	for strategy: ECSBridgeBackendStrategy in backend_strategies:
		if strategy == null or not strategy.enabled:
			continue
		if backend_types.has(strategy.bridge_type):
			push_warning(
				"ECSBridgeRegistryStrategy: duplicate backend_strategy for bridge_type %d" % strategy.bridge_type
			)
		backend_types[strategy.bridge_type] = true
	var sync_types: Dictionary = {}
	for strategy: ECSSystemStrategy in system_strategies:
		if strategy == null or not strategy.enabled:
			continue
		if strategy is ECSBridgeSyncStrategy:
			var sync_strategy: ECSBridgeSyncStrategy = strategy as ECSBridgeSyncStrategy
			sync_types[sync_strategy.bridge_type] = true
	for bridge_type: Variant in backend_types.keys():
		if not sync_types.has(bridge_type):
			push_warning(
				"ECSBridgeRegistryStrategy: backend bridge_type %d has no ECSBridgeSyncStrategy" % bridge_type
			)
