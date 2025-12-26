extends RefCounted

class_name BitMask

const MAX_INT_CAPACITY: int = 64

var _bits: PackedInt64Array

func _init(capacity: int) -> void:
	_bits = PackedInt64Array()
	bit_resize(capacity)

func bit_set(index: int, value: bool) -> void:
	var num_index: int = index / MAX_INT_CAPACITY
	var bit_index: int = index % MAX_INT_CAPACITY
	_bits[num_index] = BitMaskOperations.bit_set(_bits[num_index], bit_index) if value else BitMaskOperations.bit_clear(_bits[num_index], bit_index)

func bit_test(index: int) -> bool:
	var num_index: int = index / MAX_INT_CAPACITY
	var bit_index: int = index % MAX_INT_CAPACITY
	return BitMaskOperations.bit_test(_bits[num_index], bit_index)

func bit_resize(capacity: int) -> void:
	_bits.resize(max(1, (capacity / MAX_INT_CAPACITY) + 1))

func bit_match(small: BitMask) -> bool:
	for i in range(0, _bits.size()):
		var small_num: int = small._bits[i] if i < small._bits.size() else 0
		var big_num: int = _bits[i]
		if !BitMaskOperations.bit_match(big_num, small_num):
			return false

	return true

func bit_hash() -> int:
	return hash(_bits)

func bit_copy_from(bits: PackedInt64Array) -> void:
	_bits = bits.duplicate()

static func static_bit_match(big: BitMask, small: BitMask) -> bool:
	return big.bit_match(small)
