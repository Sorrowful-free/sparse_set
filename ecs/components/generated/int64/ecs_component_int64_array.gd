#THAT FILE WAS GENERATED PLEASE DONOT CHANGE IT

class_name ECSComponentInt64Array extends ECSComponentBaseArray

func add_entity(entity_id: int) -> void:
	var chunk: ECSComponentInt64ArrayChunk = get_or_create_chunk(entity_id)
	chunk.add_component(entity_id, 0)
	_entities_ids.append(entity_id)

func add_component(entity_id: int, component_value: int) -> void:
	var need_append: bool = !has_component(entity_id)
	var chunk: ECSComponentInt64ArrayChunk = get_or_create_chunk(entity_id)
	chunk.add_component(entity_id, component_value)
	if need_append:
		_entities_ids.append(entity_id)

func remove_component(entity_id: int) -> void:
	var chunk: ECSComponentInt64ArrayChunk = get_chunk(entity_id)
	if chunk != null:
		var chunk_entity_index: int = ECSEntityIdsUtils.get_chunk_entity_index(entity_id)
		chunk.remove_component(chunk_entity_index)

func has_component(entity_id: int) -> bool:
	var chunk: ECSComponentInt64ArrayChunk = get_chunk(entity_id)
	if chunk == null:
		return false
	return chunk.has_component(entity_id)

func set_component(entity_id: int, component_value: int) -> void:
	var chunk: ECSComponentInt64ArrayChunk = get_or_create_chunk(entity_id)
	chunk.set_component(entity_id, component_value)

func get_component(entity_id: int) -> int:
	var chunk: ECSComponentInt64ArrayChunk = get_chunk(entity_id)
	if chunk != null:
		return chunk.get_component(entity_id)
	return 0

func create_chunk() -> ECSComponentInt64ArrayChunk:
	return ECSComponentInt64ArrayChunk.new()
