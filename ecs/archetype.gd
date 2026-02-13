class_name Archetype extends RefCounted

var _bits: PackedInt64Array
var _component_ids: PackedInt64Array

var _chunks: Array[PackedInt64Array]

func _init(bits: PackedInt64Array, component_ids: PackedInt64Array) -> void:
	_bits = bits.duplicate()
	_component_ids = component_ids.duplicate()
	_chunks = []

func add_entity(entity: int) -> void:
	var chunk: PackedInt64Array = get_or_create_chunk(entity)
	var chunk_entity_index: int = EntityIdsUtils.get_chunk_entity_index(entity)
	chunk[chunk_entity_index] = entity

func remove_entity(entity: int) -> void:
	var chunk: PackedInt64Array = get_chunk(entity)
	if chunk != null:
		var chunk_entity_index: int = EntityIdsUtils.get_chunk_entity_index(entity)
		chunk[chunk_entity_index] = -1

func has_entity(entity: int) -> bool:
	var chunk_index: int = EntityIdsUtils.get_chunk_index(entity)
	
	if chunk_index >= _chunks.size():
		return false
	
	var chunk: PackedInt64Array = _chunks[chunk_index]
	var chunk_entity_index: int = EntityIdsUtils.get_chunk_entity_index(entity)
	return chunk[chunk_entity_index] == entity

func get_chunk(entity: int) -> PackedInt64Array:
	var chunk_index: int = EntityIdsUtils.get_chunk_index(entity)
	return _chunks[chunk_index]

func get_or_create_chunk(entity: int) -> PackedInt64Array:
	var chunk_index: int = EntityIdsUtils.get_chunk_index(entity)
	while _chunks.size() <= chunk_index:
		var chunk: PackedInt64Array = PackedInt64Array()
		chunk.resize(EntityIdsUtils.CHUNK_SIZE)
		chunk.fill(-1)  # Заполняем -1 как пустое значение
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
