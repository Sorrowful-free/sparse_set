class_name ECSBridgeBackend extends RefCounted

## Один bridge_type (MultiMesh, node pool, Limbo root). Реализация — в игре.
var bridge_type: int = 0

var _active: Array[int] = []
var _handle_to_entity: Dictionary[int, int] = {}

func get_active_entities() -> Array[int]:
	return _active.duplicate()

func acquire_for_entity(_entity_id: int, _ecs: ECSManager) -> int:
	push_error("ECSBridgeBackend.acquire_for_entity: override in subclass")
	return -1

func release_handle(handle: int) -> void:
	var entity_id: int = int(_handle_to_entity.get(handle, -1))
	if entity_id >= 0:
		_handle_to_entity.erase(handle)
		var idx: int = _active.find(entity_id)
		if idx >= 0:
			_active.remove_at(idx)

func on_bound(entity_id: int, handle: int, _ecs: ECSManager) -> void:
	_handle_to_entity[handle] = entity_id
	if _active.find(entity_id) < 0:
		_active.append(entity_id)

func update(_ecs: ECSManager, _delta: float) -> void:
	pass
