class_name ECSBridgeOrchestratorSystem extends ECSSystemBase

var _world: ECSWorld
var _destroy_on_release: bool = true

var _component_ids: ECSBridgeComponentIds
var _release_query: ECSQuery
var _acquire_query: ECSQuery

func _init(
	ecs_manager: ECSManager,
	world: ECSWorld,
	destroy_on_release: bool = true,
) -> void:
	super(ecs_manager)
	_world = world
	_destroy_on_release = destroy_on_release

func update(_delta: float) -> void:
	if _world == null:
		return
	var registry: ECSBridgeRegistry = _world.get_bridge_registry()
	if registry == null:
		return
	if not _ensure_queries(registry):
		return
	var ecs: ECSManager = get_ecs_manager()
	var cb: ECSCommandBuffer = get_command_buffer()
	_process_pending_release(registry, ecs, cb)
	_process_pending_acquire(registry, ecs, cb)

func _ensure_queries(registry: ECSBridgeRegistry) -> bool:
	var component_ids: ECSBridgeComponentIds = registry.get_component_ids()
	if component_ids == null:
		return false
	if _component_ids == component_ids and (_release_query != null or _acquire_query != null):
		return true
	_component_ids = component_ids
	_build_queries(get_ecs_manager())
	return _release_query != null or _acquire_query != null

func _build_queries(ecs: ECSManager) -> void:
	_release_query = null
	_acquire_query = null
	if _component_ids == null:
		return
	if _component_ids.tag_pending_release >= 0:
		_release_query = ECSQueryBuilder.new() \
			.with_component(_component_ids.tag_pending_release) \
			.build(ecs)
	if _component_ids.tag_pending_acquire >= 0:
		_acquire_query = ECSQueryBuilder.new() \
			.with_component(_component_ids.tag_pending_acquire) \
			.build(ecs)

func _process_pending_release(registry: ECSBridgeRegistry, ecs: ECSManager, cb: ECSCommandBuffer) -> void:
	if _release_query == null:
		return
	var entity_ids: PackedInt64Array = _release_query.get_entity_ids()
	for entity_id: int in entity_ids:
		registry.release_entity(entity_id, ecs)
		_clear_handle(ecs, entity_id)
		cb.remove_component(entity_id, _component_ids.tag_pending_release)
		if _destroy_on_release:
			cb.destroy_entity(entity_id)
		else:
			if _component_ids.tag_bridge >= 0:
				cb.remove_component(entity_id, _component_ids.tag_bridge)

func _process_pending_acquire(registry: ECSBridgeRegistry, ecs: ECSManager, cb: ECSCommandBuffer) -> void:
	if _acquire_query == null:
		return
	if registry.bridge_type_component_id < 0 or registry.bridge_handle_component_id < 0:
		push_error("ECSBridgeOrchestratorSystem: bridge component ids not configured on registry")
		return
	var entity_ids: PackedInt64Array = _acquire_query.get_entity_ids()
	var types: ECSComponentInt32Array = ecs.get_component_array(registry.bridge_type_component_id)
	var handles: ECSComponentInt32Array = ecs.get_component_array(registry.bridge_handle_component_id)
	if types == null or handles == null:
		return
	for entity_id: int in entity_ids:
		if not ecs.has_component(entity_id, registry.bridge_type_component_id):
			push_warning("ECSBridgeOrchestratorSystem: entity %d missing bridge_type" % entity_id)
			continue
		var bridge_type: int = types.get_component(entity_id)
		var handle: int = registry.acquire(bridge_type, entity_id, ecs)
		if handle < 0:
			continue
		handles.set_component(entity_id, handle)
		cb.remove_component(entity_id, _component_ids.tag_pending_acquire)
		if _component_ids.tag_bridge >= 0:
			cb.add_component(entity_id, _component_ids.tag_bridge)

func _clear_handle(ecs: ECSManager, entity_id: int) -> void:
	var registry: ECSBridgeRegistry = _world.get_bridge_registry()
	if registry == null or registry.bridge_handle_component_id < 0:
		return
	if not ecs.has_component(entity_id, registry.bridge_handle_component_id):
		return
	var handles: ECSComponentInt32Array = ecs.get_component_array(registry.bridge_handle_component_id)
	if handles != null:
		handles.set_component(entity_id, -1)
