class_name ECSVisualRegistryDispatcher extends ECSVisualRegistry

var _backends: Dictionary = {}
var _entity_mirror: Dictionary = {}

func register_backend(visual_type: int, backend: ECSVisualBackend) -> void:
	backend.visual_type = visual_type
	_backends[visual_type] = backend

func acquire(visual_type: int, entity_id: int, ecs: ECSManager) -> int:
	var backend: ECSVisualBackend = _backends.get(visual_type)
	if backend == null:
		return -1
	var handle: int = backend.acquire_for_entity(entity_id, ecs)
	if handle >= 0:
		_entity_mirror[entity_id] = {"visual_type": visual_type, "handle": handle}
		backend.on_bound(entity_id, handle, ecs)
	return handle

func release_entity(entity_id: int) -> void:
	var entry: Variant = _entity_mirror.get(entity_id)
	if entry == null:
		return
	var visual_type: int = entry["visual_type"]
	var handle: int = entry["handle"]
	var backend: ECSVisualBackend = _backends.get(visual_type)
	if backend != null:
		backend.release_handle(handle)
	_entity_mirror.erase(entity_id)

func sync_all(ecs: ECSManager, delta: float) -> void:
	for backend: ECSVisualBackend in _backends.values():
		backend.sync(ecs, delta)

func get_entity_mirror() -> Dictionary:
	return _entity_mirror
