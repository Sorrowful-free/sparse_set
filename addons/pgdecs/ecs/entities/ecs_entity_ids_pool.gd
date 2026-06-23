class_name ECSEntityIdsPool extends RefCounted

var _next_index: int = 0
var _free_indices: PackedInt64Array = PackedInt64Array()
var _generations: PackedInt32Array = PackedInt32Array()

func get_next_entity_id() -> int:
	var index: int = 0
	if _free_indices.size() > 0:
		var free_size: int = _free_indices.size()
		index = _free_indices[free_size - 1]
		_free_indices.resize(free_size - 1)
	else:
		index = _next_index
		_next_index += 1
		_ensure_generation_capacity(index)
		if _generations[index] == 0:
			_generations[index] = 1
	var generation: int = _generations[index]
	return ECSEntityHandle.make(index, generation)

func free_entity_id(handle: int) -> void:
	if !ECSEntityHandle.is_valid_handle(handle):
		push_error("ECSEntityIdsPool: invalid handle")
		return
	var index: int = ECSEntityHandle.index_of(handle)
	var generation: int = ECSEntityHandle.generation_of(handle)
	if index < 0 || index >= _generations.size():
		push_error("ECSEntityIdsPool: handle index out of range")
		return
	if _generations[index] != generation:
		push_error("ECSEntityIdsPool: stale or double free")
		return
	_generations[index] = generation + 1
	_free_indices.append(index)

func is_alive(handle: int) -> bool:
	if !ECSEntityHandle.is_valid_handle(handle):
		return false
	var index: int = ECSEntityHandle.index_of(handle)
	var generation: int = ECSEntityHandle.generation_of(handle)
	if index < 0 || index >= _generations.size():
		return false
	return _generations[index] == generation && generation > 0

func _ensure_generation_capacity(index: int) -> void:
	if index >= _generations.size():
		_generations.resize(index + 1)
