class_name ECSArchetypeChunk extends RefCounted

## Чанк архетипа: фиксированные слоты (index → slot) + плотный список для итерации.

var _slots: PackedInt64Array
var _dense: PackedInt64Array
var _slot_to_dense: PackedInt32Array
var _dense_slots: PackedInt32Array
var _count: int = 0
var _structural_version: int = 0

func _init() -> void:
	_slots = PackedInt64Array()
	_slots.resize(ECSEntityIdsUtils.CHUNK_SIZE)
	_slots.fill(ECSEntityIdsUtils.NULL_ENTITY_ID)
	_dense = PackedInt64Array()
	_dense.resize(ECSEntityIdsUtils.CHUNK_SIZE)
	_dense.fill(ECSEntityIdsUtils.NULL_ENTITY_ID)
	_slot_to_dense = PackedInt32Array()
	_slot_to_dense.resize(ECSEntityIdsUtils.CHUNK_SIZE)
	_slot_to_dense.fill(-1)
	_dense_slots = PackedInt32Array()
	_dense_slots.resize(ECSEntityIdsUtils.CHUNK_SIZE)
	_dense_slots.fill(-1)

func add_entity(handle: int) -> void:
	var entity_index: int = ECSEntityHandle.index_of(handle)
	var slot: int = ECSEntityIdsUtils.get_chunk_entity_index(entity_index)
	var existing_handle: int = _slots[slot]
	if existing_handle == ECSEntityIdsUtils.NULL_ENTITY_ID:
		_dense[_count] = handle
		_dense_slots[_count] = slot
		_slot_to_dense[slot] = _count
		_count += 1
	elif existing_handle == handle:
		return
	else:
		var dense_index: int = _slot_to_dense[slot]
		if dense_index >= 0 && dense_index < _count:
			_dense[dense_index] = handle
	_structural_version += 1
	_slots[slot] = handle

func remove_entity(handle: int) -> void:
	var entity_index: int = ECSEntityHandle.index_of(handle)
	var slot: int = ECSEntityIdsUtils.get_chunk_entity_index(entity_index)
	if _slots[slot] != handle:
		return
	_structural_version += 1
	var dense_index: int = _slot_to_dense[slot]
	if dense_index < 0 || dense_index >= _count:
		_slots[slot] = ECSEntityIdsUtils.NULL_ENTITY_ID
		return
	_slots[slot] = ECSEntityIdsUtils.NULL_ENTITY_ID
	_slot_to_dense[slot] = -1
	var last_idx: int = _count - 1
	if dense_index != last_idx:
		var swapped_handle: int = _dense[last_idx]
		_dense[dense_index] = swapped_handle
		var swapped_slot: int = ECSEntityIdsUtils.slot_from_handle(swapped_handle)
		_slot_to_dense[swapped_slot] = dense_index
		_dense_slots[dense_index] = swapped_slot
	_dense[last_idx] = ECSEntityIdsUtils.NULL_ENTITY_ID
	_dense_slots[last_idx] = -1
	_count -= 1

func has_entity(handle: int) -> bool:
	var entity_index: int = ECSEntityHandle.index_of(handle)
	var slot: int = ECSEntityIdsUtils.get_chunk_entity_index(entity_index)
	return _slots[slot] == handle

func get_entity_count() -> int:
	return _count

func get_structural_version() -> int:
	return _structural_version

## Плотный буфер handle. Читать только индексы [0, get_entity_count()).
func get_dense_entities() -> PackedInt64Array:
	return _dense

## Плотный буфер slot по dense_index. Читать только [0, get_entity_count()).
func get_dense_slots() -> PackedInt32Array:
	return _dense_slots

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
	_dense.fill(ECSEntityIdsUtils.NULL_ENTITY_ID)
	_slot_to_dense.fill(-1)
	_dense_slots.fill(-1)
	_count = 0
	_structural_version += 1
