#THAT FILE WAS GENERATED PLEASE DONOT CHANGE IT

class_name ECSComponentVector3iArray extends ECSComponentBaseArray

func add_entity(entity_id: int) -> void:
	var chunk: ECSComponentVector3iArrayChunk = get_or_create_chunk(entity_id)
	chunk.add_component(entity_id, Vector3i.ZERO)

func add_component(entity_id: int, component_value: Vector3i) -> void:
	var chunk: ECSComponentVector3iArrayChunk = get_or_create_chunk(entity_id)
	chunk.add_component(entity_id, component_value)

func remove_component(entity_id: int) -> void:
	var chunk: ECSComponentVector3iArrayChunk = get_chunk(entity_id)
	if chunk != null:
		var slot: int = ECSEntityIdsUtils.slot_from_handle(entity_id)
		chunk.remove_component(slot)

func set_component(entity_id: int, component_value: Vector3i) -> void:
	var chunk: ECSComponentVector3iArrayChunk = get_or_create_chunk(entity_id)
	chunk.set_component(entity_id, component_value)

func get_component(entity_id: int) -> Vector3i:
	var chunk: ECSComponentVector3iArrayChunk = get_chunk(entity_id)
	if chunk != null:
		return chunk.get_component(entity_id)
	return Vector3i.ZERO

func create_chunk() -> ECSComponentVector3iArrayChunk:
	return ECSComponentVector3iArrayChunk.new()
