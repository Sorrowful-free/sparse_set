@abstract class_name ComponentBase extends RefCounted

var _chunk_capacity: int
var _chunks: Array[ComponentChunkBase]
var _entities_ids: SparseSet

func _init(component_capacity: int, chunk_capacity: int) -> void:
	_chunk_capacity = chunk_capacity
	_chunks = []
	_entities_ids = SparseSet.new(component_capacity)

func size_chunks() -> int:
	return _chunks.size()

func size_entities() -> int:
	return _entities_ids.get_size()

func get_chunks() -> Array[ComponentChunkBase]:
	return _chunks

func get_entities_ids() -> PackedInt32Array:
	return _entities_ids.get_packed()

func clear() -> void:
	for chunk: ComponentChunkBase in _chunks:
		chunk.clear()
	_chunks.clear()
	_entities_ids.clear()

func get_or_create_chunk(entity_id: int) -> ComponentChunkBase:
	var chunk: ComponentChunkBase = get_chunk(entity_id)
	if chunk != null:
		return chunk

	chunk = create_chunk(_chunk_capacity)
	_chunks.append(chunk)
	return chunk

func get_chunk(entity_id: int) -> ComponentChunkBase:
	var chunk_index: int = EntityIdsUtils.get_chunk_index(entity_id, _chunk_capacity)
	if _chunks.size() <= chunk_index:
		return null
	return _chunks[chunk_index]

func add_entity(entity_id: int) -> void:
	_entities_ids.add(entity_id)

func remove_entity(entity_id: int) -> void:
	_entities_ids.remove(entity_id)

func has_entity(entity_id: int) -> bool:
	return _entities_ids.has(entity_id)

@abstract func create_chunk(chunk_capacity: int) -> ComponentChunkBase
