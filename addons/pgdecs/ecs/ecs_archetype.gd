class_name ECSArchetype extends RefCounted

var _bits: PackedInt64Array
var _component_ids: PackedInt64Array
var _bitmask: ECSBitMask

var _chunks: Array[ECSArchetypeChunk]

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
	get_or_create_chunk(entity_index).add_entity(entity)

func remove_entity(entity: int) -> void:
	var entity_index: int = ECSEntityHandle.index_of(entity)
	var chunk: ECSArchetypeChunk = get_archetype_chunk(entity_index)
	if chunk != null:
		chunk.remove_entity(entity)

func has_entity(entity: int) -> bool:
	var entity_index: int = ECSEntityHandle.index_of(entity)
	var chunk: ECSArchetypeChunk = get_archetype_chunk(entity_index)
	if chunk == null:
		return false
	return chunk.has_entity(entity)

func get_archetype_chunk(entity_index: int) -> ECSArchetypeChunk:
	var chunk_index: int = ECSEntityIdsUtils.get_chunk_index(entity_index)
	if chunk_index < 0 || chunk_index >= _chunks.size():
		return null
	return _chunks[chunk_index]

func get_or_create_chunk(entity_index: int) -> ECSArchetypeChunk:
	var chunk_index: int = ECSEntityIdsUtils.get_chunk_index(entity_index)
	while _chunks.size() <= chunk_index:
		_chunks.append(ECSArchetypeChunk.new())
	return _chunks[chunk_index]

func add_component_id(component_id: int) -> void:
	_component_ids.append(component_id)

func remove_component_id(component_id: int) -> void:
	_component_ids.erase(component_id)

func get_chunks() -> Array[ECSArchetypeChunk]:
	return _chunks

func clear() -> void:
	for chunk: ECSArchetypeChunk in _chunks:
		chunk.clear()
	_chunks.clear()
