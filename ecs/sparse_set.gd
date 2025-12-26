extends RefCounted
class_name SparseSet

var _packed: PackedInt32Array
var _dense: PackedInt32Array
var _size: int
var _capacity: int

func _init(capacity: int) -> void:
	_packed = PackedInt32Array()
	_dense = PackedInt32Array()
	
	_packed.resize(capacity)
	_dense.resize(capacity)
	
	_capacity = capacity
 

func has(x: int) -> bool:
	if x < 0 || x >= _capacity:
		return false
	
	return _dense[x] < _size && _packed[_dense[x]] == x
  
func add(x: int) -> int:
	if has(x):
		return take_index(x)

	var index: int = _size
	_dense[x] = index
	_packed[index] = x
	_size = _size + 1
	return index

func remove(x: int) -> void:
	if !has(x):
		return
	
	var last_index: int = _size - 1
	var last: int = _packed[last_index]
	_size = _size - 1
	if x != last:
		_dense[last] = _dense[x]
		_packed[_dense[x]] = last

func take_by_index(index: int) -> int:
	assert(index >= 0 && index < _size, "Index :%d out of size:%d" % [index, _size])
	return _packed[index]

func take_index(x: int) -> int:
	if !has(x):
		return -1
	return _dense[x]

func get_dense() -> PackedInt32Array:
	return _dense

func get_packed() -> PackedInt32Array:
	return _packed

func get_size() -> int:
	return _size

func get_capacity() -> int:
	return _capacity

func clear() -> void:
	_dense.clear()
	_packed.clear()
	_capacity = 0
