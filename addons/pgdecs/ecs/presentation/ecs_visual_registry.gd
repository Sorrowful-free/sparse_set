class_name ECSVisualRegistry extends RefCounted

## Маршрутизатор visual backends. Handle/type хранятся в SoA-компонентах игры.
var visual_type_component_id: int = -1
var visual_handle_component_id: int = -1

var _backends: Dictionary[int, ECSVisualBackend] = {}

func register_backend(visual_type: int, backend: ECSVisualBackend) -> void:
	backend.visual_type = visual_type
	_backends[visual_type] = backend

func absorb(other: ECSVisualRegistry) -> void:
	if other == null:
		return
	if other == self:
		return
	_merge_component_ids_from(other)
	for visual_type: int in other._backends:
		if _backends.has(visual_type):
			if OS.is_debug_build():
				push_error("ECSVisualRegistry.absorb: duplicate visual_type %d" % visual_type)
			continue
		register_backend(visual_type, other._backends[visual_type])

func _merge_component_ids_from(other: ECSVisualRegistry) -> void:
	if visual_type_component_id < 0 and other.visual_type_component_id >= 0:
		visual_type_component_id = other.visual_type_component_id
	elif other.visual_type_component_id >= 0 and visual_type_component_id != other.visual_type_component_id:
		if OS.is_debug_build():
			push_error("ECSVisualRegistry.absorb: visual_type_component_id mismatch")
	if visual_handle_component_id < 0 and other.visual_handle_component_id >= 0:
		visual_handle_component_id = other.visual_handle_component_id
	elif other.visual_handle_component_id >= 0 and visual_handle_component_id != other.visual_handle_component_id:
		if OS.is_debug_build():
			push_error("ECSVisualRegistry.absorb: visual_handle_component_id mismatch")

func acquire(visual_type: int, entity_id: int, ecs: ECSManager) -> int:
	var backend: ECSVisualBackend = _backends.get(visual_type)
	if backend == null:
		push_warning("ECSVisualRegistry.acquire: unknown visual_type %d" % visual_type)
		return -1
	var handle: int = backend.acquire_for_entity(entity_id, ecs)
	if handle >= 0:
		backend.on_bound(entity_id, handle, ecs)
	return handle

func release_entity(entity_id: int, ecs: ECSManager) -> void:
	if visual_type_component_id < 0 or visual_handle_component_id < 0:
		push_error("ECSVisualRegistry.release_entity: visual_type_component_id and visual_handle_component_id required")
		return
	if not ecs.has_component(entity_id, visual_type_component_id):
		return
	if not ecs.has_component(entity_id, visual_handle_component_id):
		return
	var types: ECSComponentInt32Array = ecs.get_component_array(visual_type_component_id)
	var handles: ECSComponentInt32Array = ecs.get_component_array(visual_handle_component_id)
	if types == null or handles == null:
		return
	var visual_type: int = types.get_component(entity_id)
	var handle: int = handles.get_component(entity_id)
	if handle < 0:
		return
	var backend: ECSVisualBackend = _backends.get(visual_type)
	if backend != null:
		backend.release_handle(handle)

func sync_all(ecs: ECSManager, delta: float) -> void:
	for backend: ECSVisualBackend in _backends.values():
		backend.sync(ecs, delta)
