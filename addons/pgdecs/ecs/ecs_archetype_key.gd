extends RefCounted

class_name ECSArchetypeKey

## Канонический ключ архетипа: нормализованный PackedInt64Array (sort + unique component ids).

static func make_from_packed_ids(normalized_ids: PackedInt64Array) -> PackedInt64Array:
	return normalized_ids.duplicate()

static func make_from_bitmask(_bits: ECSBitMask, packed_ids: PackedInt64Array) -> PackedInt64Array:
	return make_from_packed_ids(packed_ids)

static func equals(a: PackedInt64Array, b: PackedInt64Array) -> bool:
	if a.size() != b.size():
		return false
	for i in range(a.size()):
		if a[i] != b[i]:
			return false
	return true
