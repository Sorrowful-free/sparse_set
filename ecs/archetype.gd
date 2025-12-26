class_name Archetype extends RefCounted

var _bits: PackedInt64Array
var _component_ids: PackedInt64Array

var _chunk_capacity: int
var _chunks: Array[PackedInt64Array]

func _init(bits: PackedInt64Array, component_ids: PackedInt64Array, chunk_capacity: int) -> void:
	_bits = bits.duplicate()
	_component_ids = component_ids.duplicate()
	_chunk_capacity = chunk_capacity
	_chunks = []

func add_entity(entity: int) -> void:
	var chunk: PackedInt64Array = get_or_create_chunk(entity)
	var chunk_entity_index: int = EntityIdsUtils.get_chunk_entity_index(entity, _chunk_capacity)
	chunk[chunk_entity_index] = entity

func remove_entity(entity: int) -> void:
	var chunk: PackedInt64Array = get_chunk(entity)
	if chunk != null:
		var chunk_entity_index: int = EntityIdsUtils.get_chunk_entity_index(entity, _chunk_capacity)
		chunk[chunk_entity_index] = -1

func has_entity(entity: int) -> bool:
	var chunk_index: int = EntityIdsUtils.get_chunk_index(entity, _chunk_capacity)
	
	if chunk_index >= _chunks.size():
		return false
	
	var chunk: PackedInt64Array = _chunks[chunk_index]
	var chunk_entity_index: int = EntityIdsUtils.get_chunk_entity_index(entity, _chunk_capacity)
	return chunk[chunk_entity_index] == entity

func get_chunk(entity: int) -> PackedInt64Array:
	var chunk_index: int = EntityIdsUtils.get_chunk_index(entity, _chunk_capacity)
	return _chunks[chunk_index]

func get_or_create_chunk(entity: int) -> PackedInt64Array:
	var chunk_index: int = EntityIdsUtils.get_chunk_index(entity, _chunk_capacity)
	while _chunks.size() <= chunk_index:
		var chunk: PackedInt64Array = PackedInt64Array()
		chunk.resize(_chunk_capacity)
		chunk.fill(-1)  # Заполняем -1 как пустое значение
		_chunks.append(chunk)
	return _chunks[chunk_index]

func add_component_id(component_id: int) -> void:
	_component_ids.append(component_id)

func remove_component_id(component_id: int) -> void:
	_component_ids.erase(component_id)

func get_chunks() -> Array[PackedInt64Array]:
	return _chunks

func get_chunk_capacity() -> int:
	return _chunk_capacity

func clear() -> void:
	for chunk: PackedInt64Array in _chunks:
		chunk.clear()
	_chunks.clear()
