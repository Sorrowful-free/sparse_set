class_name ECSArchetype extends RefCounted

var _bits: PackedInt64Array
var _component_ids: PackedInt64Array
var _bitmask: ECSBitMask

var _chunks: Array[PackedInt64Array]

func _init(bits: PackedInt64Array, component_ids: PackedInt64Array) -> void:
	_bits = bits.duplicate()
	_component_ids = component_ids.duplicate()
	_chunks = []
	var max_component_id: int = 0
	for component_id in _component_ids:
		if component_id > max_component_id:
			max_component_id = component_id
	_bitmask = ECSBitMask.new(max_component_id + 1)
	_bitmask.bit_copy_from(_bits)

func get_bitmask() -> ECSBitMask:
	return _bitmask

func add_entity(entity: int) -> void:
	var entity_index: int = ECSEntityHandle.index_of(entity)
	var chunk: PackedInt64Array = get_or_create_chunk(entity_index)
	var chunk_entity_index: int = ECSEntityIdsUtils.get_chunk_entity_index(entity_index)
	chunk[chunk_entity_index] = entity

func remove_entity(entity: int) -> void:
	var entity_index: int = ECSEntityHandle.index_of(entity)
	var chunk: PackedInt64Array = get_chunk(entity_index)
	if chunk.is_empty():
		return
	var chunk_entity_index: int = ECSEntityIdsUtils.get_chunk_entity_index(entity_index)
	chunk[chunk_entity_index] = -1

func has_entity(entity: int) -> bool:
	var entity_index: int = ECSEntityHandle.index_of(entity)
	var chunk_index: int = ECSEntityIdsUtils.get_chunk_index(entity_index)
	if chunk_index >= _chunks.size():
		return false
	var chunk: PackedInt64Array = _chunks[chunk_index]
	var chunk_entity_index: int = ECSEntityIdsUtils.get_chunk_entity_index(entity_index)
	return chunk[chunk_entity_index] == entity

func get_chunk(entity_index: int) -> PackedInt64Array:
	var chunk_index: int = ECSEntityIdsUtils.get_chunk_index(entity_index)
	if chunk_index < 0 || chunk_index >= _chunks.size():
		return PackedInt64Array()
	return _chunks[chunk_index]

func get_or_create_chunk(entity_index: int) -> PackedInt64Array:
	var chunk_index: int = ECSEntityIdsUtils.get_chunk_index(entity_index)
	while _chunks.size() <= chunk_index:
		var chunk: PackedInt64Array = PackedInt64Array()
		chunk.resize(ECSEntityIdsUtils.CHUNK_SIZE)
		chunk.fill(-1)
		_chunks.append(chunk)
	return _chunks[chunk_index]

func add_component_id(component_id: int) -> void:
	_component_ids.append(component_id)

func remove_component_id(component_id: int) -> void:
	_component_ids.erase(component_id)

func get_chunks() -> Array[PackedInt64Array]:
	return _chunks

func clear() -> void:
	for chunk: PackedInt64Array in _chunks:
		chunk.clear()
	_chunks.clear()
