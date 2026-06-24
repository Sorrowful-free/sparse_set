class_name ECSArchetype extends RefCounted

var _bits: PackedInt64Array
var _component_ids: PackedInt64Array
var _bitmask: ECSBitMask

## Sparse map chunk_index → ECSArchetypeChunk: sparse[chunk_index] = dense_index + 1 (0 = нет).
var _chunk_sparse: PackedInt32Array = PackedInt32Array()
var _dense_chunk_indices: PackedInt32Array = PackedInt32Array()
var _dense_chunks: Array[ECSArchetypeChunk] = []
var _live_count: int = 0

var _batch_counts: PackedInt32Array = PackedInt32Array()
var _batch_offsets: PackedInt32Array = PackedInt32Array()
var _batch_write_pos: PackedInt32Array = PackedInt32Array()
var _batch_entity_scratch: PackedInt64Array = PackedInt64Array()
var _batch_group_scratch: PackedInt64Array = PackedInt64Array()
var _batch_unique_chunk_indices: PackedInt32Array = PackedInt32Array()
var _batch_chunk_remap: PackedInt32Array = PackedInt32Array()
var _batch_group_sparse_mode: bool = false

const _BATCH_SPARSE_BUCKET_MAX: int = 512

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

func remove_entity(entity: int) -> int:
	var entity_index: int = ECSEntityHandle.index_of(entity)
	var chunk_index: int = ECSEntityIdsUtils.get_chunk_index(entity_index)
	var chunk: ECSArchetypeChunk = get_archetype_chunk_by_index(chunk_index)
	if chunk == null || !chunk.has_entity(entity):
		return -1
	chunk.remove_entity(entity)
	_live_count -= 1
	if chunk.get_entity_count() == 0:
		_remove_chunk_index(chunk_index)
		return chunk_index
	return -1

func remove_entities_batch(entity_ids: PackedInt64Array) -> bool:
	if entity_ids.is_empty():
		return false
	var any_chunk_removed: bool = false
	var single_chunk_index: int = _try_get_single_chunk_index(entity_ids)
	if single_chunk_index >= 0:
		var chunk: ECSArchetypeChunk = get_archetype_chunk_by_index(single_chunk_index)
		if chunk != null:
			var removed: int = chunk.remove_entities_batch(entity_ids)
			_live_count -= removed
			if chunk.get_entity_count() == 0:
				_remove_chunk_index(single_chunk_index)
				any_chunk_removed = true
		return any_chunk_removed
	var bucket_count: int = _group_entity_ids_by_chunk(entity_ids)
	for bucket_index in range(bucket_count):
		var group_size: int = _batch_counts[bucket_index]
		if group_size == 0:
			continue
		var chunk_index: int = _batch_group_chunk_index(bucket_index)
		var chunk: ECSArchetypeChunk = get_archetype_chunk_by_index(chunk_index)
		if chunk == null:
			continue
		var start: int = _batch_offsets[bucket_index]
		_batch_group_scratch.resize(group_size)
		for j in range(group_size):
			_batch_group_scratch[j] = _batch_entity_scratch[start + j]
		var removed: int = chunk.remove_entities_batch(_batch_group_scratch)
		_live_count -= removed
		if chunk.get_entity_count() == 0:
			_remove_chunk_index(chunk_index)
			any_chunk_removed = true
	return any_chunk_removed

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

## PackedInt32Array передаётся по ссылке — не мутировать.
func get_dense_chunk_indices() -> PackedInt32Array:
	return _dense_chunk_indices

## Hot path: обход chunk_index без аллокации Array[int].
func for_each_chunk_index(callback: Callable) -> void:
	for i in range(_dense_chunk_indices.size()):
		callback.call(_dense_chunk_indices[i])

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

func _try_get_single_chunk_index(entity_ids: PackedInt64Array) -> int:
	if entity_ids.is_empty():
		return -1
	var chunk_index: int = ECSEntityIdsUtils.chunk_index_from_handle(entity_ids[0])
	for i in range(1, entity_ids.size()):
		if ECSEntityIdsUtils.chunk_index_from_handle(entity_ids[i]) != chunk_index:
			return -1
	return chunk_index

func _ensure_batch_bucket_capacity(bucket_count: int) -> void:
	if _batch_counts.size() < bucket_count:
		_batch_counts.resize(bucket_count)
		_batch_offsets.resize(bucket_count)
		_batch_write_pos.resize(bucket_count)

func _batch_unique_bucket_index(chunk_index: int, unique_count: int) -> int:
	for i in range(unique_count):
		if _batch_unique_chunk_indices[i] == chunk_index:
			return i
	return -1

func _group_entity_ids_by_chunk_sparse(entity_ids: PackedInt64Array, max_chunk_index: int) -> int:
	var entity_count: int = entity_ids.size()
	var bucket_count: int = max_chunk_index + 1
	_ensure_batch_bucket_capacity(bucket_count)
	for i in range(bucket_count):
		_batch_counts[i] = 0
	for i in range(entity_count):
		var chunk_index: int = ECSEntityIdsUtils.chunk_index_from_handle(entity_ids[i])
		_batch_counts[chunk_index] += 1
	var running_offset: int = 0
	for i in range(bucket_count):
		_batch_offsets[i] = running_offset
		running_offset += _batch_counts[i]
	_batch_entity_scratch.resize(running_offset)
	for i in range(bucket_count):
		_batch_write_pos[i] = _batch_offsets[i]
	for i in range(entity_count):
		var entity_id: int = entity_ids[i]
		var chunk_index: int = ECSEntityIdsUtils.chunk_index_from_handle(entity_id)
		var write_index: int = _batch_write_pos[chunk_index]
		_batch_entity_scratch[write_index] = entity_id
		_batch_write_pos[chunk_index] = write_index + 1
	_batch_group_sparse_mode = true
	return bucket_count

func _group_entity_ids_by_chunk_compact(entity_ids: PackedInt64Array) -> int:
	var entity_count: int = entity_ids.size()
	var unique_count: int = 0
	var max_chunk_index: int = 0
	for i in range(entity_count):
		var chunk_index: int = ECSEntityIdsUtils.chunk_index_from_handle(entity_ids[i])
		if chunk_index > max_chunk_index:
			max_chunk_index = chunk_index
		if _batch_unique_bucket_index(chunk_index, unique_count) >= 0:
			continue
		if unique_count >= _batch_unique_chunk_indices.size():
			_batch_unique_chunk_indices.resize(maxi(unique_count + 1, 8))
		_batch_unique_chunk_indices[unique_count] = chunk_index
		unique_count += 1
	var use_remap: bool = max_chunk_index + 1 <= _BATCH_SPARSE_BUCKET_MAX
	if use_remap:
		if _batch_chunk_remap.size() < max_chunk_index + 1:
			_batch_chunk_remap.resize(max_chunk_index + 1)
		for i in range(max_chunk_index + 1):
			_batch_chunk_remap[i] = -1
		for i in range(unique_count):
			_batch_chunk_remap[_batch_unique_chunk_indices[i]] = i
	_ensure_batch_bucket_capacity(unique_count)
	for i in range(unique_count):
		_batch_counts[i] = 0
	for i in range(entity_count):
		var chunk_index: int = ECSEntityIdsUtils.chunk_index_from_handle(entity_ids[i])
		var bucket_index: int
		if use_remap:
			bucket_index = _batch_chunk_remap[chunk_index]
		else:
			bucket_index = _batch_unique_bucket_index(chunk_index, unique_count)
		_batch_counts[bucket_index] += 1
	var running_offset: int = 0
	for i in range(unique_count):
		_batch_offsets[i] = running_offset
		running_offset += _batch_counts[i]
	_batch_entity_scratch.resize(running_offset)
	for i in range(unique_count):
		_batch_write_pos[i] = _batch_offsets[i]
	for i in range(entity_count):
		var entity_id: int = entity_ids[i]
		var chunk_index: int = ECSEntityIdsUtils.chunk_index_from_handle(entity_id)
		var bucket_index: int
		if use_remap:
			bucket_index = _batch_chunk_remap[chunk_index]
		else:
			bucket_index = _batch_unique_bucket_index(chunk_index, unique_count)
		var write_index: int = _batch_write_pos[bucket_index]
		_batch_entity_scratch[write_index] = entity_id
		_batch_write_pos[bucket_index] = write_index + 1
	_batch_group_sparse_mode = false
	return unique_count

func _batch_group_chunk_index(bucket_index: int) -> int:
	if _batch_group_sparse_mode:
		return bucket_index
	return _batch_unique_chunk_indices[bucket_index]

func _group_entity_ids_by_chunk(entity_ids: PackedInt64Array) -> int:
	var entity_count: int = entity_ids.size()
	if entity_count == 0:
		return 0
	var max_chunk_index: int = 0
	for i in range(entity_count):
		var chunk_index: int = ECSEntityIdsUtils.chunk_index_from_handle(entity_ids[i])
		if chunk_index > max_chunk_index:
			max_chunk_index = chunk_index
	if max_chunk_index + 1 <= maxi(entity_count, 64):
		return _group_entity_ids_by_chunk_sparse(entity_ids, max_chunk_index)
	return _group_entity_ids_by_chunk_compact(entity_ids)
