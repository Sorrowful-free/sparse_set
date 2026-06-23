@abstract class_name ECSComponentBaseArray extends RefCounted

var _chunks: Array[ECSComponentBaseArrayChunk]

func _init() -> void:
	_chunks = []

@abstract func add_entity(entity_id: int) -> void

func add_entities_batch(entity_ids: PackedInt64Array) -> void:
	if entity_ids.is_empty():
		return
	for entity_id in entity_ids:
		add_entity(entity_id)

func remove_entity(entity_id: int) -> void:
	var chunk: ECSComponentBaseArrayChunk = get_chunk(entity_id)
	if chunk != null:
		chunk.remove_component(ECSEntityIdsUtils.slot_from_handle(entity_id))

func remove_entities_batch(entity_ids: PackedInt64Array) -> void:
	if entity_ids.is_empty():
		return
	for entity_id in entity_ids:
		remove_entity(entity_id)

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
	while _chunks.size() <= chunk_index:
		_chunks.append(create_chunk())
	return _chunks[chunk_index]

func get_chunk(entity_id: int) -> ECSComponentBaseArrayChunk:
	var chunk_index: int = ECSEntityIdsUtils.chunk_index_from_handle(entity_id)
	if _chunks.size() <= chunk_index:
		return null
	return _chunks[chunk_index]

@abstract func create_chunk() -> ECSComponentBaseArrayChunk
