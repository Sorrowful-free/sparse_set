#THAT FILE WAS GENERATED PLEASE DONOT CHANGE IT

class_name ECSComponentVector3Array extends ECSComponentBaseArray

func add_entity(entity_id: int) -> void:
	var chunk: ECSComponentVector3ArrayChunk = get_or_create_chunk(entity_id)
	chunk.add_component(entity_id, Vector3.ZERO)

func add_component(entity_id: int, component_value: Vector3) -> void:
	var chunk: ECSComponentVector3ArrayChunk = get_or_create_chunk(entity_id)
	chunk.add_component(entity_id, component_value)

func remove_component(entity_id: int) -> void:
	var chunk: ECSComponentVector3ArrayChunk = get_chunk(entity_id)
	if chunk != null:
		var entity_index: int = ECSEntityHandle.index_of(entity_id)
		chunk.remove_component(ECSEntityIdsUtils.get_chunk_entity_index(entity_index))

func has_component(entity_id: int) -> bool:
	var chunk: ECSComponentVector3ArrayChunk = get_chunk(entity_id)
	if chunk == null:
		return false
	return chunk.has_component(entity_id)

func set_component(entity_id: int, component_value: Vector3) -> void:
	var chunk: ECSComponentVector3ArrayChunk = get_or_create_chunk(entity_id)
	chunk.set_component(entity_id, component_value)

func get_component(entity_id: int) -> Vector3:
	var chunk: ECSComponentVector3ArrayChunk = get_chunk(entity_id)
	if chunk != null:
		return chunk.get_component(entity_id)
	return Vector3.ZERO

func create_chunk() -> ECSComponentVector3ArrayChunk:
	return ECSComponentVector3ArrayChunk.new()
