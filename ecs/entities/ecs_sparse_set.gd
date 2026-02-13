class_name ECSSparseSet extends RefCounted

## Sparse set: плотный массив (dense) + разрежённый (sparse) для O(1) add/remove/has.
## sparse[entity_id] = индекс в dense; -1 если сущности нет. Оба массива PackedInt64Array.

var _dense: PackedInt64Array
var _sparse: PackedInt64Array

const EMPTY: int = -1

func _init() -> void:
	_dense = PackedInt64Array()
	_sparse = PackedInt64Array()

func _ensure_sparse_capacity(entity_id: int) -> void:
	if entity_id >= _sparse.size():
		var old_size: int = _sparse.size()
		_sparse.resize(entity_id + 1)
		for i in range(old_size, _sparse.size()):
			_sparse[i] = EMPTY

func add(entity_id: int) -> void:
	if entity_id < 0:
		return
	_ensure_sparse_capacity(entity_id)
	_sparse[entity_id] = _dense.size()
	_dense.append(entity_id)

func remove(entity_id: int) -> void:
	if entity_id < 0:
		return
	if _dense.is_empty():
		return
	if entity_id >= _sparse.size():
		return
	var idx: int = _sparse[entity_id]
	if idx < 0:
		return
	var last_idx: int = _dense.size() - 1
	if idx != last_idx:
		var last_entity_id: int = _dense[last_idx]
		_dense[idx] = last_entity_id
		_ensure_sparse_capacity(last_entity_id)
		_sparse[last_entity_id] = idx
	_dense.resize(last_idx)
	_sparse[entity_id] = EMPTY

func has(entity_id: int) -> bool:
	if entity_id < 0:
		return false
	if entity_id >= _sparse.size():
		return false
	return _sparse[entity_id] >= 0

func size() -> int:
	return _dense.size()

func get_ids() -> PackedInt64Array:
	return _dense.duplicate()

func clear() -> void:
	_dense.clear()
	_sparse.clear()
