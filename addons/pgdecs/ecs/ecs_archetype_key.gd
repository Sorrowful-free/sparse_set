extends RefCounted

class_name ECSArchetypeKey

## Канонический ключ архетипа: нормализованный PackedInt64Array (sort + unique component ids).

static func copy_key(normalized_ids: PackedInt64Array) -> PackedInt64Array:
	return normalized_ids.duplicate()

static func make_from_packed_ids(normalized_ids: PackedInt64Array) -> PackedInt64Array:
	return copy_key(normalized_ids)

static func make_from_bitmask(_bits: ECSBitMask, packed_ids: PackedInt64Array) -> PackedInt64Array:
	return make_from_packed_ids(packed_ids)

static func equals(a: PackedInt64Array, b: PackedInt64Array) -> bool:
	if a.size() != b.size():
		return false
	for i in range(a.size()):
		if a[i] != b[i]:
			return false
	return true

## Стабильный hash нормализованного набора component ids (FNV-1a). Не гарантирует уникальность.
static func hash_packed_ids(normalized_ids: PackedInt64Array) -> int:
	var hash_value: int = 2166136261
	for i in range(normalized_ids.size()):
		var word: int = normalized_ids[i]
		hash_value = int((hash_value * 16777619) & 0x7fffffff)
		hash_value = hash_value ^ int(word & 0x7fffffff)
		hash_value = int((hash_value * 16777619) & 0x7fffffff)
		hash_value = hash_value ^ int((word >> 31) & 0x7fffffff)
	return hash_value
