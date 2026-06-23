extends RefCounted

class_name ECSBitMask

const MAX_INT_CAPACITY: int = 64
const INDEX_SHIFT: int = 6
const INDEX_MASK: int = 63

var _bits: PackedInt64Array
var _hash_cache: int = 0
var _hash_dirty: bool = true

func _init(capacity: int) -> void:
	_bits = PackedInt64Array()
	bit_resize(capacity)

func bit_set(index: int, value: bool) -> void:
	var num_index: int = index >> INDEX_SHIFT
	var bit_index: int = index & INDEX_MASK
	if num_index >= _bits.size():
		bit_resize((num_index + 1) * MAX_INT_CAPACITY)
	var current_word: int = _bits[num_index]
	var updated_word: int = ECSBitMaskOperations.bit_set(current_word, bit_index) if value else ECSBitMaskOperations.bit_clear(current_word, bit_index)
	if updated_word != current_word:
		_bits[num_index] = updated_word
		_hash_dirty = true

func bit_test(index: int) -> bool:
	var num_index: int = index >> INDEX_SHIFT
	var bit_index: int = index & INDEX_MASK
	if num_index >= _bits.size():
		return false
	return ECSBitMaskOperations.bit_test(_bits[num_index], bit_index)

func bit_resize(capacity: int) -> void:
	var word_count: int = 1
	if capacity > 0:
		word_count = ((capacity - 1) >> INDEX_SHIFT) + 1
	if _bits.size() != word_count:
		_bits.resize(word_count)
		_hash_dirty = true

## Обнуляет все биты маски (для переиспользования буфера, Фаза D).
func bit_clear_all() -> void:
	var changed: bool = false
	for i in range(_bits.size()):
		if _bits[i] != 0:
			changed = true
		_bits[i] = 0
	if changed:
		_hash_dirty = true

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
	if !_hash_dirty:
		return _hash_cache
	var last_nonzero: int = _bits.size() - 1
	while last_nonzero >= 0 && _bits[last_nonzero] == 0:
		last_nonzero -= 1
	if last_nonzero < 0:
		_hash_cache = 0
		_hash_dirty = false
		return _hash_cache
	var hash_value: int = 2166136261
	for i in range(last_nonzero + 1):
		var word: int = _bits[i]
		hash_value = int((hash_value * 16777619) & 0x7fffffff)
		hash_value = hash_value ^ int(word & 0x7fffffff)
		hash_value = int((hash_value * 16777619) & 0x7fffffff)
		hash_value = hash_value ^ int((word >> 31) & 0x7fffffff)
	_hash_cache = hash_value
	_hash_dirty = false
	return _hash_cache

func bit_copy_from(bits: PackedInt64Array) -> void:
	_bits = bits.duplicate()
	_hash_dirty = true

static func static_bit_match(big: ECSBitMask, small: ECSBitMask) -> bool:
	return big.bit_match(small)
