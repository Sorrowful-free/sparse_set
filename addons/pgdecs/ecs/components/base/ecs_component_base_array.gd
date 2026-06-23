@abstract class_name ECSComponentBaseArray extends RefCounted

var _chunks: Array[ECSComponentBaseArrayChunk]

## Переиспользуемые scratch-буферы для batch fast-path (без Dictionary).
var _batch_counts: PackedInt32Array = PackedInt32Array()
var _batch_offsets: PackedInt32Array = PackedInt32Array()
var _batch_write_pos: PackedInt32Array = PackedInt32Array()
var _batch_entity_scratch: PackedInt64Array = PackedInt64Array()
var _batch_slot_scratch: PackedInt32Array = PackedInt32Array()

const _BATCH_FAST_PATH_MIN_SIZE: int = 2

func _init() -> void:
	_chunks = []

@abstract func add_entity(entity_id: int) -> void

func add_entities_batch(entity_ids: PackedInt64Array) -> void:
	if entity_ids.is_empty():
		return
	if entity_ids.size() < _BATCH_FAST_PATH_MIN_SIZE || _batch_has_invalid_entity_id(entity_ids):
		for entity_id in entity_ids:
			add_entity(entity_id)
		return
	_add_entities_batch_fast(entity_ids)

func remove_entity(entity_id: int) -> void:
	var chunk: ECSComponentBaseArrayChunk = get_chunk(entity_id)
	if chunk != null:
		chunk.remove_component(ECSEntityIdsUtils.slot_from_handle(entity_id))

func remove_entities_batch(entity_ids: PackedInt64Array) -> void:
	if entity_ids.is_empty():
		return
	if entity_ids.size() < _BATCH_FAST_PATH_MIN_SIZE || _batch_has_invalid_entity_id(entity_ids):
		for entity_id in entity_ids:
			remove_entity(entity_id)
		return
	_remove_entities_batch_fast(entity_ids)

func size_chunks() -> int:
	return _chunks.size()

func get_chunks() -> Array[ECSComponentBaseArrayChunk]:
	return _chunks

func get_chunk_by_index(chunk_index: int) -> ECSComponentBaseArrayChunk:
	if chunk_index < 0 || chunk_index >= _chunks.size():
		return null
	return _chunks[chunk_index]

func clear() -> void:
	for chunk: ECSComponentBaseArrayChunk in _chunks:
		chunk.clear()
	_chunks.clear()

func get_or_create_chunk(entity_id: int) -> ECSComponentBaseArrayChunk:
	var chunk_index: int = ECSEntityIdsUtils.chunk_index_from_handle(entity_id)
	return _get_or_create_chunk_by_index(chunk_index)

func get_chunk(entity_id: int) -> ECSComponentBaseArrayChunk:
	var chunk_index: int = ECSEntityIdsUtils.chunk_index_from_handle(entity_id)
	if _chunks.size() <= chunk_index:
		return null
	return _chunks[chunk_index]

@abstract func create_chunk() -> ECSComponentBaseArrayChunk

func _batch_has_invalid_entity_id(entity_ids: PackedInt64Array) -> bool:
	for entity_id in entity_ids:
		if entity_id <= 0:
			return true
	return false

func _ensure_batch_bucket_capacity(bucket_count: int) -> void:
	if _batch_counts.size() < bucket_count:
		_batch_counts.resize(bucket_count)
		_batch_offsets.resize(bucket_count)
		_batch_write_pos.resize(bucket_count)

func _group_entity_ids_by_chunk(entity_ids: PackedInt64Array) -> int:
	var entity_count: int = entity_ids.size()
	var max_chunk_index: int = 0
	for i in range(entity_count):
		var chunk_index: int = ECSEntityIdsUtils.chunk_index_from_handle(entity_ids[i])
		if chunk_index > max_chunk_index:
			max_chunk_index = chunk_index
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
	return bucket_count

func _get_or_create_chunk_by_index(chunk_index: int) -> ECSComponentBaseArrayChunk:
	while _chunks.size() <= chunk_index:
		_chunks.append(create_chunk())
	return _chunks[chunk_index]

func _try_get_single_chunk_index(entity_ids: PackedInt64Array) -> int:
	if entity_ids.is_empty():
		return -1
	var chunk_index: int = ECSEntityIdsUtils.chunk_index_from_handle(entity_ids[0])
	for i in range(1, entity_ids.size()):
		if ECSEntityIdsUtils.chunk_index_from_handle(entity_ids[i]) != chunk_index:
			return -1
	return chunk_index

func _add_entities_batch_fast(entity_ids: PackedInt64Array) -> void:
	var single_chunk_index: int = _try_get_single_chunk_index(entity_ids)
	if single_chunk_index >= 0:
		var chunk: ECSComponentBaseArrayChunk = _get_or_create_chunk_by_index(single_chunk_index)
		chunk.add_components_batch(entity_ids)
		return
	var bucket_count: int = _group_entity_ids_by_chunk(entity_ids)
	for chunk_index in range(bucket_count):
		var group_size: int = _batch_counts[chunk_index]
		if group_size == 0:
			continue
		var chunk: ECSComponentBaseArrayChunk = _get_or_create_chunk_by_index(chunk_index)
		var start: int = _batch_offsets[chunk_index]
		if group_size == 1:
			var single: PackedInt64Array = PackedInt64Array()
			single.resize(1)
			single[0] = _batch_entity_scratch[start]
			chunk.add_components_batch(single)
		else:
			chunk.add_components_batch(_batch_entity_scratch.slice(start, start + group_size))

func _remove_entities_batch_fast(entity_ids: PackedInt64Array) -> void:
	var single_chunk_index: int = _try_get_single_chunk_index(entity_ids)
	if single_chunk_index >= 0:
		if single_chunk_index < _chunks.size():
			var chunk: ECSComponentBaseArrayChunk = _chunks[single_chunk_index]
			if chunk != null:
				_batch_slot_scratch.resize(entity_ids.size())
				for j in range(entity_ids.size()):
					_batch_slot_scratch[j] = ECSEntityIdsUtils.slot_from_handle(entity_ids[j])
				chunk.remove_components_batch(_batch_slot_scratch)
		return
	var bucket_count: int = _group_entity_ids_by_chunk(entity_ids)
	for chunk_index in range(bucket_count):
		var group_size: int = _batch_counts[chunk_index]
		if group_size == 0:
			continue
		if chunk_index >= _chunks.size():
			continue
		var chunk: ECSComponentBaseArrayChunk = _chunks[chunk_index]
		if chunk == null:
			continue
		var start: int = _batch_offsets[chunk_index]
		_batch_slot_scratch.resize(group_size)
		for j in range(group_size):
			_batch_slot_scratch[j] = ECSEntityIdsUtils.slot_from_handle(_batch_entity_scratch[start + j])
		chunk.remove_components_batch(_batch_slot_scratch)
