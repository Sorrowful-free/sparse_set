#THAT FILE WAS GENERATED PLEASE DONOT CHANGE IT

class_name ComponentVector4Array extends ComponentBaseArray

func add_entity(entity_id: int) -> void:
	var chunk: ComponentVector4ArrayChunk = get_or_create_chunk(entity_id)
	chunk.add_component(entity_id, Vector4.ZERO)
	_entities_ids.append(entity_id)

func add_component(entity_id: int, component_value: Vector4) -> void:
	var need_append: bool = !has_component(entity_id)
	var chunk: ComponentVector4ArrayChunk = get_or_create_chunk(entity_id)
	chunk.add_component(entity_id, component_value)
	if need_append:
		_entities_ids.append(entity_id)

func remove_component(entity_id: int) -> void:
	var chunk: ComponentVector4ArrayChunk = get_chunk(entity_id)
	if chunk != null:
		var chunk_entity_index: int = EntityIdsUtils.get_chunk_entity_index(entity_id)
		chunk.remove_component(chunk_entity_index)

func has_component(entity_id: int) -> bool:
	var chunk: ComponentVector4ArrayChunk = get_chunk(entity_id)
	if chunk == null:
		return false
	return chunk.has_component(entity_id)

func set_component(entity_id: int, component_value: Vector4) -> void:
	var chunk: ComponentVector4ArrayChunk = get_or_create_chunk(entity_id)
	chunk.set_component(entity_id, component_value)

func get_component(entity_id: int) -> Vector4:
	var chunk: ComponentVector4ArrayChunk = get_chunk(entity_id)
	if chunk != null:
		return chunk.get_component(entity_id)
	return Vector4.ZERO

func create_chunk() -> ComponentVector4ArrayChunk:
	return ComponentVector4ArrayChunk.new()
