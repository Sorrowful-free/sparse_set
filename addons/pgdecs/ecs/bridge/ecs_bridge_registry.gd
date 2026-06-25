class_name ECSBridgeRegistry extends RefCounted

## Маршрутизатор bridge backends. Handle/type хранятся в SoA-компонентах игры.
var bridge_type_component_id: int = -1
var bridge_handle_component_id: int = -1

var _component_ids: ECSBridgeComponentIds
var _backends: Dictionary[int, ECSBridgeBackend] = {}

func apply_component_ids(component_ids: ECSBridgeComponentIds) -> void:
	if component_ids == null:
		return
	_component_ids = component_ids
	bridge_type_component_id = component_ids.bridge_type_id
	bridge_handle_component_id = component_ids.bridge_handle_id

func get_component_ids() -> ECSBridgeComponentIds:
	return _component_ids

func register_backend(bridge_type: int, backend: ECSBridgeBackend) -> void:
	backend.bridge_type = bridge_type
	_backends[bridge_type] = backend

func get_backend(bridge_type: int) -> ECSBridgeBackend:
	return _backends.get(bridge_type)

func get_registered_bridge_types() -> Array:
	return _backends.keys()

func acquire(bridge_type: int, entity_id: int, ecs: ECSManager) -> int:
	var backend: ECSBridgeBackend = _backends.get(bridge_type)
	if backend == null:
		push_warning("ECSBridgeRegistry.acquire: unknown bridge_type %d" % bridge_type)
		return -1
	var handle: int = backend.acquire_for_entity(entity_id, ecs)
	if handle >= 0:
		backend.on_bound(entity_id, handle, ecs)
	return handle

func release_entity(entity_id: int, ecs: ECSManager) -> void:
	if bridge_type_component_id < 0 or bridge_handle_component_id < 0:
		push_error("ECSBridgeRegistry.release_entity: bridge_type_component_id and bridge_handle_component_id required")
		return
	if not ecs.has_component(entity_id, bridge_type_component_id):
		return
	if not ecs.has_component(entity_id, bridge_handle_component_id):
		return
	var types: ECSComponentInt32Array = ecs.get_component_array(bridge_type_component_id)
	var handles: ECSComponentInt32Array = ecs.get_component_array(bridge_handle_component_id)
	if types == null or handles == null:
		return
	var type_value: int = types.get_component(entity_id)
	var handle: int = handles.get_component(entity_id)
	if handle < 0:
		return
	var backend: ECSBridgeBackend = _backends.get(type_value)
	if backend != null:
		backend.release_handle(handle)
