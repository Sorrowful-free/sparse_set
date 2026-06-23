class_name ECSArchetypeChunk extends RefCounted

## Чанк архетипа: фиксированные слоты (index → slot) + плотный список для итерации.

var _slots: PackedInt64Array
var _dense: PackedInt64Array
var _count: int = 0

func _init() -> void:
	_slots = PackedInt64Array()
	_slots.resize(ECSEntityIdsUtils.CHUNK_SIZE)
	_slots.fill(ECSEntityIdsUtils.NULL_ENTITY_ID)
	_dense = PackedInt64Array()
	_dense.resize(ECSEntityIdsUtils.CHUNK_SIZE)

func add_entity(handle: int) -> void:
	var entity_index: int = ECSEntityHandle.index_of(handle)
	var slot: int = ECSEntityIdsUtils.get_chunk_entity_index(entity_index)
	if _slots[slot] == ECSEntityIdsUtils.NULL_ENTITY_ID:
		_dense[_count] = handle
		_count += 1
	_slots[slot] = handle

func remove_entity(handle: int) -> void:
	var entity_index: int = ECSEntityHandle.index_of(handle)
	var slot: int = ECSEntityIdsUtils.get_chunk_entity_index(entity_index)
	if _slots[slot] != handle:
		return
	_slots[slot] = ECSEntityIdsUtils.NULL_ENTITY_ID
	for i in range(_count):
		if _dense[i] == handle:
			var last_idx: int = _count - 1
			if i != last_idx:
				_dense[i] = _dense[last_idx]
			_count -= 1
			return

func has_entity(handle: int) -> bool:
	var entity_index: int = ECSEntityHandle.index_of(handle)
	var slot: int = ECSEntityIdsUtils.get_chunk_entity_index(entity_index)
	return _slots[slot] == handle

func get_entity_count() -> int:
	return _count

## Плотный буфер handle. Читать только индексы [0, get_entity_count()).
func get_dense_entities() -> PackedInt64Array:
	return _dense

func get_dense_entity_at(dense_index: int) -> int:
	if dense_index < 0 || dense_index >= _count:
		return ECSEntityIdsUtils.NULL_ENTITY_ID
	return _dense[dense_index]

func get_slot_entity_id(slot_index: int) -> int:
	if slot_index < 0 || slot_index >= _slots.size():
		return ECSEntityIdsUtils.NULL_ENTITY_ID
	return _slots[slot_index]

func get_slots() -> PackedInt64Array:
	return _slots

func clear() -> void:
	_slots.fill(ECSEntityIdsUtils.NULL_ENTITY_ID)
	_count = 0
