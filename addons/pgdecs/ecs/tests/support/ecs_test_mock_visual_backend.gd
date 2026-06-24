class_name ECSTestMockVisualBackend extends ECSVisualBackend

var acquire_count: int = 0
var release_count: int = 0
var sync_count: int = 0
var last_handle: int = -1
var _free_slots: Array[int] = [0, 1, 2]

func acquire_for_entity(_entity_id: int, _ecs: ECSManager) -> int:
	acquire_count += 1
	if _free_slots.is_empty():
		return -1
	last_handle = _free_slots.pop_back()
	return last_handle

func release_handle(_handle: int) -> void:
	release_count += 1
	_free_slots.append(_handle)

func sync(_ecs: ECSManager, _delta: float) -> void:
	sync_count += 1
