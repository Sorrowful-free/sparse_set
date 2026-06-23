extends RefCounted

class_name ECSBitMask

const MAX_INT_CAPACITY: int = 64
const INDEX_SHIFT: int = 6
const INDEX_MASK: int = 63

var _bits: PackedInt64Array

func _init(capacity: int) -> void:
	_bits = PackedInt64Array()
	bit_resize(capacity)

func bit_set(index: int, value: bool) -> void:
	var num_index: int = index >> INDEX_SHIFT
	var bit_index: int = index & INDEX_MASK
	if num_index >= _bits.size():
		bit_resize((num_index + 1) * MAX_INT_CAPACITY)
	_bits[num_index] = ECSBitMaskOperations.bit_set(_bits[num_index], bit_index) if value else ECSBitMaskOperations.bit_clear(_bits[num_index], bit_index)

func bit_test(index: int) -> bool:
	var num_index: int = index >> INDEX_SHIFT
	var bit_index: int = index & INDEX_MASK
	if num_index >= _bits.size():
		return false
	return ECSBitMaskOperations.bit_test(_bits[num_index], bit_index)

func bit_resize(capacity: int) -> void:
	var word_count: int = 1
	if capacity > 0:
		word_count = ((capacity - 1) / MAX_INT_CAPACITY) + 1
	_bits.resize(word_count)

## Обнуляет все биты маски (для переиспользования буфера, Фаза D).
func bit_clear_all() -> void:
	for i in range(_bits.size()):
		_bits[i] = 0

func bit_match(small: ECSBitMask) -> bool:
	for i in range(0, small._bits.size()):
		var small_num: int = small._bits[i]
		var big_num: int = _bits[i] if i < _bits.size() else 0
		if !ECSBitMaskOperations.bit_match(big_num, small_num):
			return false
	return true

## Возвращает true, если эта маска и other имеют хотя бы один общий установленный бит.
func bit_has_any(other: ECSBitMask) -> bool:
	var min_size: int = mini(_bits.size(), other._bits.size())
	for i in range(min_size):
		if (_bits[i] & other._bits[i]) != 0:
			return true
	return false

func bit_hash() -> int:
	return hash(_normalized_bits())

func _normalized_bits() -> PackedInt64Array:
	var last_nonzero: int = _bits.size() - 1
	while last_nonzero >= 0 && _bits[last_nonzero] == 0:
		last_nonzero -= 1
	if last_nonzero < 0:
		return PackedInt64Array([0])
	return _bits.slice(0, last_nonzero + 1)

func bit_copy_from(bits: PackedInt64Array) -> void:
	_bits = bits.duplicate()

static func static_bit_match(big: ECSBitMask, small: ECSBitMask) -> bool:
	return big.bit_match(small)
