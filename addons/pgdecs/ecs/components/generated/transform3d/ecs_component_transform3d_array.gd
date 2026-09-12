#THAT FILE WAS GENERATED PLEASE DONOT CHANGE IT

class_name ECSComponentTransform3DArray extends ECSComponentBaseArray

func add_entity(entity_id: int) -> void:
	var chunk: ECSComponentTransform3DArrayChunk = get_or_create_chunk(entity_id)
	chunk.add_component(entity_id, Transform3D.IDENTITY)

func add_component(entity_id: int, component_value: Transform3D) -> void:
	var chunk: ECSComponentTransform3DArrayChunk = get_or_create_chunk(entity_id)
	chunk.add_component(entity_id, component_value)

func remove_component(entity_id: int) -> void:
	var chunk: ECSComponentTransform3DArrayChunk = get_chunk(entity_id)
	if chunk != null:
		var slot: int = ECSEntityIdsUtils.slot_from_handle(entity_id)
		chunk.remove_component(slot)

func set_component(entity_id: int, component_value: Transform3D) -> void:
	var chunk: ECSComponentTransform3DArrayChunk = get_or_create_chunk(entity_id)
	chunk.set_component(entity_id, component_value)

func get_component(entity_id: int) -> Transform3D:
	var chunk: ECSComponentTransform3DArrayChunk = get_chunk(entity_id)
	if chunk != null:
		return chunk.get_component(entity_id)
	return Transform3D.IDENTITY

func create_chunk() -> ECSComponentTransform3DArrayChunk:
	return ECSComponentTransform3DArrayChunk.new()
