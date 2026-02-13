#THAT FILE WAS GENERATED PLEASE DONOT CHANGE IT

class_name ComponentFloat64Array extends ComponentBaseArray

func add_entity(entity_id: int) -> void:
	var chunk: ComponentFloat64ArrayChunk = get_or_create_chunk(entity_id)
	chunk.add_component(entity_id, 0.0)
	_entities_ids.append(entity_id)

func add_component(entity_id: int, component_value: float) -> void:
	var need_append: bool = !has_component(entity_id)
	var chunk: ComponentFloat64ArrayChunk = get_or_create_chunk(entity_id)
	chunk.add_component(entity_id, component_value)
	if need_append:
		_entities_ids.append(entity_id)

func remove_component(entity_id: int) -> void:
	var chunk: ComponentFloat64ArrayChunk = get_chunk(entity_id)
	if chunk != null:
		var chunk_entity_index: int = EntityIdsUtils.get_chunk_entity_index(entity_id)
		chunk.remove_component(chunk_entity_index)

func has_component(entity_id: int) -> bool:
	var chunk: ComponentFloat64ArrayChunk = get_chunk(entity_id)
	if chunk == null:
		return false
	return chunk.has_component(entity_id)

func set_component(entity_id: int, component_value: float) -> void:
	var chunk: ComponentFloat64ArrayChunk = get_or_create_chunk(entity_id)
	chunk.set_component(entity_id, component_value)

func get_component(entity_id: int) -> float:
	var chunk: ComponentFloat64ArrayChunk = get_chunk(entity_id)
	if chunk != null:
		return chunk.get_component(entity_id)
	return 0.0

func create_chunk() -> ComponentFloat64ArrayChunk:
	return ComponentFloat64ArrayChunk.new()
