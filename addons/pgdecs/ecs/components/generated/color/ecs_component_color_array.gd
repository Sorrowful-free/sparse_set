#THAT FILE WAS GENERATED PLEASE DONOT CHANGE IT

class_name ECSComponentColorArray extends ECSComponentBaseArray

func add_entity(entity_id: int) -> void:
	var chunk: ECSComponentColorArrayChunk = get_or_create_chunk(entity_id)
	chunk.add_component(entity_id, Color.BLACK)

func add_component(entity_id: int, component_value: Color) -> void:
	var chunk: ECSComponentColorArrayChunk = get_or_create_chunk(entity_id)
	chunk.add_component(entity_id, component_value)

func remove_component(entity_id: int) -> void:
	var chunk: ECSComponentColorArrayChunk = get_chunk(entity_id)
	if chunk != null:
		var entity_index: int = ECSEntityHandle.index_of(entity_id)
		chunk.remove_component(ECSEntityIdsUtils.get_chunk_entity_index(entity_index))

func has_component(entity_id: int) -> bool:
	var chunk: ECSComponentColorArrayChunk = get_chunk(entity_id)
	if chunk == null:
		return false
	return chunk.has_component(entity_id)

func set_component(entity_id: int, component_value: Color) -> void:
	var chunk: ECSComponentColorArrayChunk = get_or_create_chunk(entity_id)
	chunk.set_component(entity_id, component_value)

func get_component(entity_id: int) -> Color:
	var chunk: ECSComponentColorArrayChunk = get_chunk(entity_id)
	if chunk != null:
		return chunk.get_component(entity_id)
	return Color.BLACK

func create_chunk() -> ECSComponentColorArrayChunk:
	return ECSComponentColorArrayChunk.new()
