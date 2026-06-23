@abstract class_name ECSComponentBaseArray extends RefCounted

var _chunks: Array[ECSComponentBaseArrayChunk]

func _init() -> void:
	_chunks = []

## Добавляет сущность в компонент с дефолтным значением. Реализуется в сгенерированных классах.
@abstract func add_entity(entity_id: int) -> void

## Батч: добавляет сущности с дефолтным значением (группировка по чанкам).
func add_entities_batch(entity_ids: PackedInt64Array) -> void:
	if entity_ids.is_empty():
		return
	var by_chunk: Dictionary[int, PackedInt64Array] = {}
	for entity_id in entity_ids:
		var entity_index: int = ECSEntityHandle.index_of(entity_id)
		var chunk_index: int = ECSEntityIdsUtils.get_chunk_index(entity_index)
		if !by_chunk.has(chunk_index):
			by_chunk[chunk_index] = PackedInt64Array()
		by_chunk[chunk_index].append(entity_id)
	for chunk_index in by_chunk:
		var ids_in_chunk: PackedInt64Array = by_chunk[chunk_index]
		var chunk: ECSComponentBaseArrayChunk = get_or_create_chunk(ids_in_chunk[0])
		chunk.add_components_batch(ids_in_chunk)

func remove_entity(entity_id: int) -> void:
	var chunk: ECSComponentBaseArrayChunk = get_chunk(entity_id)
	if chunk != null:
		var entity_index: int = ECSEntityHandle.index_of(entity_id)
		chunk.remove_component(ECSEntityIdsUtils.get_chunk_entity_index(entity_index))

## Батч: удаляет сущности из компонента (группировка по чанкам, один проход по чанку).
func remove_entities_batch(entity_ids: PackedInt64Array) -> void:
	if entity_ids.is_empty():
		return
	var by_chunk: Dictionary[int, PackedInt64Array] = {}
	for entity_id in entity_ids:
		var entity_index: int = ECSEntityHandle.index_of(entity_id)
		var chunk_index: int = ECSEntityIdsUtils.get_chunk_index(entity_index)
		if !by_chunk.has(chunk_index):
			by_chunk[chunk_index] = PackedInt64Array()
		by_chunk[chunk_index].append(entity_id)
	for chunk_index in by_chunk:
		var ids_in_chunk: PackedInt64Array = by_chunk[chunk_index]
		var chunk: ECSComponentBaseArrayChunk = get_chunk(ids_in_chunk[0])
		if chunk == null:
			continue
		var indices: PackedInt32Array = PackedInt32Array()
		for entity_id in ids_in_chunk:
			var entity_index: int = ECSEntityHandle.index_of(entity_id)
			indices.append(ECSEntityIdsUtils.get_chunk_entity_index(entity_index))
		chunk.remove_components_batch(indices)

func has_entity(entity_id: int) -> bool:
	var chunk: ECSComponentBaseArrayChunk = get_chunk(entity_id)
	return chunk != null && chunk.has_component(entity_id)

func size_chunks() -> int:
	return _chunks.size()

func size_entities() -> int:
	var total: int = 0
	for chunk: ECSComponentBaseArrayChunk in _chunks:
		var entity_ids: PackedInt64Array = chunk.get_entity_ids()
		for i in range(entity_ids.size()):
			if entity_ids[i] >= 0:
				total += 1
	return total

func get_chunks() -> Array[ECSComponentBaseArrayChunk]:
	return _chunks

func get_chunk_by_index(chunk_index: int) -> ECSComponentBaseArrayChunk:
	if chunk_index < 0 || chunk_index >= _chunks.size():
		return null
	return _chunks[chunk_index]

func get_entities_ids() -> PackedInt64Array:
	var result: PackedInt64Array = PackedInt64Array()
	for chunk: ECSComponentBaseArrayChunk in _chunks:
		var entity_ids: PackedInt64Array = chunk.get_entity_ids()
		for i in range(entity_ids.size()):
			if entity_ids[i] >= 0:
				result.append(entity_ids[i])
	return result

func clear() -> void:
	for chunk: ECSComponentBaseArrayChunk in _chunks:
		chunk.clear()
	_chunks.clear()

func get_or_create_chunk(entity_id: int) -> ECSComponentBaseArrayChunk:
	var entity_index: int = ECSEntityHandle.index_of(entity_id)
	var chunk_index: int = ECSEntityIdsUtils.get_chunk_index(entity_index)
	while _chunks.size() <= chunk_index:
		_chunks.append(create_chunk())
	return _chunks[chunk_index]

func get_chunk(entity_id: int) -> ECSComponentBaseArrayChunk:
	var entity_index: int = ECSEntityHandle.index_of(entity_id)
	var chunk_index: int = ECSEntityIdsUtils.get_chunk_index(entity_index)
	if _chunks.size() <= chunk_index:
		return null
	return _chunks[chunk_index]

@abstract func create_chunk() -> ECSComponentBaseArrayChunk
