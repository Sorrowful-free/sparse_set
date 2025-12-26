@abstract class_name ComponentChunkBase extends RefCounted

var _sparse_set: SparseSet
var _capacity: int

func _init(capacity: int) -> void:
	_sparse_set = SparseSet.new(capacity)
	_capacity = capacity

func get_size() -> int:
	return _sparse_set.get_size()

func get_capacity() -> int:
	return _capacity

func get_entity_ids() -> PackedInt32Array:
	return _sparse_set.get_packed()

func clear() -> void:
	_sparse_set.clear()
