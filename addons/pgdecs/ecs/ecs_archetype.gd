class_name ECSArchetype extends RefCounted

var _bits: PackedInt64Array
var _component_ids: PackedInt64Array
var _bitmask: ECSBitMask

## Sparse map chunk_index → ECSArchetypeChunk: sparse[chunk_index] = dense_index + 1 (0 = нет).
var _chunk_sparse: PackedInt32Array = PackedInt32Array()
var _dense_chunk_indices: PackedInt32Array = PackedInt32Array()
var _dense_chunks: Array[ECSArchetypeChunk] = []
var _live_count: int = 0

func _init(bits: PackedInt64Array, component_ids: PackedInt64Array) -> void:
	_bits = bits.duplicate()
	_component_ids = component_ids.duplicate()
	var max_component_id: int = 0
	for component_id in _component_ids:
		if component_id > max_component_id:
			max_component_id = component_id
	_bitmask = ECSBitMask.new(max_component_id + 1)
	_bitmask.bit_copy_from(_bits)

func get_bitmask() -> ECSBitMask:
	return _bitmask

func get_live_count() -> int:
	return _live_count

func _ensure_chunk_sparse_capacity(chunk_index: int) -> void:
	if chunk_index >= _chunk_sparse.size():
		_chunk_sparse.resize(chunk_index + 1)

func add_entity(entity: int) -> void:
	var entity_index: int = ECSEntityHandle.index_of(entity)
	var chunk: ECSArchetypeChunk = get_or_create_chunk(entity_index)
	if chunk.has_entity(entity):
		return
	chunk.add_entity(entity)
	_live_count += 1

func remove_entity(entity: int) -> void:
	var entity_index: int = ECSEntityHandle.index_of(entity)
	var chunk_index: int = ECSEntityIdsUtils.get_chunk_index(entity_index)
	var chunk: ECSArchetypeChunk = get_archetype_chunk_by_index(chunk_index)
	if chunk == null || !chunk.has_entity(entity):
		return
	chunk.remove_entity(entity)
	_live_count -= 1
	if chunk.get_entity_count() == 0:
		_remove_chunk_index(chunk_index)

func remove_entities_batch(entity_ids: PackedInt64Array) -> void:
	for entity_id: int in entity_ids:
		remove_entity(entity_id)

func has_entity(entity: int) -> bool:
	var entity_index: int = ECSEntityHandle.index_of(entity)
	var chunk: ECSArchetypeChunk = get_archetype_chunk(entity_index)
	if chunk == null:
		return false
	return chunk.has_entity(entity)

func get_chunk_indices() -> Array[int]:
	var result: Array[int] = []
	result.resize(_dense_chunk_indices.size())
	for i in range(_dense_chunk_indices.size()):
		result[i] = _dense_chunk_indices[i]
	return result

func get_archetype_chunk_by_index(chunk_index: int) -> ECSArchetypeChunk:
	if chunk_index < 0 || chunk_index >= _chunk_sparse.size():
		return null
	var stored: int = _chunk_sparse[chunk_index]
	if stored == 0:
		return null
	return _dense_chunks[stored - 1]

func get_archetype_chunk(entity_index: int) -> ECSArchetypeChunk:
	var chunk_index: int = ECSEntityIdsUtils.get_chunk_index(entity_index)
	return get_archetype_chunk_by_index(chunk_index)

func get_or_create_chunk(entity_index: int) -> ECSArchetypeChunk:
	var chunk_index: int = ECSEntityIdsUtils.get_chunk_index(entity_index)
	var existing: ECSArchetypeChunk = get_archetype_chunk_by_index(chunk_index)
	if existing != null:
		return existing
	_ensure_chunk_sparse_capacity(chunk_index)
	var chunk: ECSArchetypeChunk = ECSArchetypeChunk.new()
	_dense_chunks.append(chunk)
	_dense_chunk_indices.append(chunk_index)
	_chunk_sparse[chunk_index] = _dense_chunks.size()
	return chunk

func _remove_chunk_index(chunk_index: int) -> void:
	if chunk_index < 0 || chunk_index >= _chunk_sparse.size():
		return
	var stored: int = _chunk_sparse[chunk_index]
	if stored == 0:
		return
	var dense_index: int = stored - 1
	var last_index: int = _dense_chunks.size() - 1
	if dense_index != last_index:
		var swapped_chunk_index: int = _dense_chunk_indices[last_index]
		_dense_chunks[dense_index] = _dense_chunks[last_index]
		_dense_chunk_indices[dense_index] = swapped_chunk_index
		_chunk_sparse[swapped_chunk_index] = dense_index + 1
	_dense_chunks.resize(last_index)
	_dense_chunk_indices.resize(last_index)
	_chunk_sparse[chunk_index] = 0

func add_component_id(component_id: int) -> void:
	_component_ids.append(component_id)

func remove_component_id(component_id: int) -> void:
	_component_ids.erase(component_id)

func get_chunks() -> Array[ECSArchetypeChunk]:
	var result: Array[ECSArchetypeChunk] = []
	result.resize(_dense_chunks.size())
	for i in range(_dense_chunks.size()):
		result[i] = _dense_chunks[i]
	return result

func clear() -> void:
	for chunk: ECSArchetypeChunk in _dense_chunks:
		chunk.clear()
	_chunk_sparse = PackedInt32Array()
	_dense_chunk_indices = PackedInt32Array()
	_dense_chunks.clear()
	_live_count = 0
