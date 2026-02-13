@abstract class_name ECSComponentBaseArray extends RefCounted

var _chunks: Array[ECSComponentBaseArrayChunk]
var _entity_set: ECSSparseSet

func _init() -> void:
	_chunks = []
	_entity_set = ECSSparseSet.new()

## Регистрирует entity_id в sparse set (вызывать из наследников при add_entity/add_component). O(1).
func _append_entity_id(entity_id: int) -> void:
	_entity_set.add(entity_id)

## Добавляет сущность в компонент с дефолтным значением. Реализуется в сгенерированных классах.
@abstract func add_entity(entity_id: int) -> void

func remove_entity(entity_id: int) -> void:
	var chunk: ECSComponentBaseArrayChunk = get_chunk(entity_id)
	if chunk != null:
		chunk.remove_component(ECSEntityIdsUtils.get_chunk_entity_index(entity_id))
	_entity_set.remove(entity_id)

func has_entity(entity_id: int) -> bool:
	var chunk: ECSComponentBaseArrayChunk = get_chunk(entity_id)
	return chunk != null && chunk.has_component(entity_id)

func size_chunks() -> int:
	return _chunks.size()

func size_entities() -> int:
	return _entity_set.size()

func get_chunks() -> Array[ECSComponentBaseArrayChunk]:
	return _chunks

func get_entities_ids() -> PackedInt64Array:
	return _entity_set.get_ids()

func clear() -> void:
	for chunk: ECSComponentBaseArrayChunk in _chunks:
		chunk.clear()
	_chunks.clear()
	_entity_set.clear()

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
