#THAT FILE WAS GENERATED PLEASE DONOT CHANGE IT

class_name ECSComponentFloat64Array extends ECSComponentBaseArray

func add_entity(entity_id: int) -> void:
	var chunk: ECSComponentFloat64ArrayChunk = get_or_create_chunk(entity_id)
	chunk.add_component(entity_id, 0.0)

func add_component(entity_id: int, component_value: float) -> void:
	var chunk: ECSComponentFloat64ArrayChunk = get_or_create_chunk(entity_id)
	chunk.add_component(entity_id, component_value)

func remove_component(entity_id: int) -> void:
	var chunk: ECSComponentFloat64ArrayChunk = get_chunk(entity_id)
	if chunk != null:
		var entity_index: int = ECSEntityHandle.index_of(entity_id)
		chunk.remove_component(ECSEntityIdsUtils.get_chunk_entity_index(entity_index))

func has_component(entity_id: int) -> bool:
	var chunk: ECSComponentFloat64ArrayChunk = get_chunk(entity_id)
	if chunk == null:
		return false
	return chunk.has_component(entity_id)

func set_component(entity_id: int, component_value: float) -> void:
	var chunk: ECSComponentFloat64ArrayChunk = get_or_create_chunk(entity_id)
	chunk.set_component(entity_id, component_value)

func get_component(entity_id: int) -> float:
	var chunk: ECSComponentFloat64ArrayChunk = get_chunk(entity_id)
	if chunk != null:
		return chunk.get_component(entity_id)
	return 0.0

func create_chunk() -> ECSComponentFloat64ArrayChunk:
	return ECSComponentFloat64ArrayChunk.new()
