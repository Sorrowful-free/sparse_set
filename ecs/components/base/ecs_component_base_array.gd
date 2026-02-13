@abstract class_name ECSComponentBaseArray extends RefCounted

var _chunks: Array[ECSECSComponentBaseArrayChunk]
var _entities_ids: PackedInt64Array

func _init() -> void:
	_chunks = []
	_entities_ids = PackedInt64Array()

## Добавляет сущность в компонент с дефолтным значением. Реализуется в сгенерированных классах.
@abstract func add_entity(entity_id: int) -> void

func remove_entity(entity_id: int) -> void:
	var chunk: ECSComponentBaseArrayChunk = get_chunk(entity_id)
	if chunk != null:
		chunk.remove_component(ECSEntityIdsUtils.get_chunk_entity_index(entity_id))

func has_entity(entity_id: int) -> bool:
	var chunk: ECSComponentBaseArrayChunk = get_chunk(entity_id)
	return chunk != null && chunk.has_component(entity_id)

func size_chunks() -> int:
	return _chunks.size()

func size_entities() -> int:
	var n: int = 0
	for ch: ECSComponentBaseArrayChunk in _chunks:
		n += ch.get_size()
	return n

func get_chunks() -> Array[ECSComponentBaseArrayChunk]:
	return _chunks

func get_entities_ids() -> PackedInt64Array:
	var result: PackedInt64Array = PackedInt64Array()
	for ch: ECSComponentBaseArrayChunk in _chunks:
		var ids: PackedInt32Array = ch.get_entity_ids()
		for i in range(ids.size()):
			if ids[i] >= 0:
				result.append(ids[i])
	return result

func clear() -> void:
	for chunk: ECSComponentBaseArrayChunk in _chunks:
		chunk.clear()
	_chunks.clear()
	_entities_ids.clear()

func get_or_create_chunk(entity_id: int) -> ECSComponentBaseArrayChunk:
	var chunk_index: int = ECSEntityIdsUtils.get_chunk_index(entity_id)
	while _chunks.size() <= chunk_index:
		_chunks.append(create_chunk())
	return _chunks[chunk_index]

func get_chunk(entity_id: int) -> ECSComponentBaseArrayChunk:
	var chunk_index: int = ECSEntityIdsUtils.get_chunk_index(entity_id)
	if _chunks.size() <= chunk_index:
		return null
	return _chunks[chunk_index]

@abstract func create_chunk() -> ECSComponentBaseArrayChunk
