#THAT FILE WAS GENERATED PLEASE DONOT CHANGE IT

class_name ECSComponentTransform2DArray extends ECSComponentBaseArray

func add_entity(entity_id: int) -> void:
	var chunk: ECSComponentTransform2DArrayChunk = get_or_create_chunk(entity_id)
	chunk.add_component(entity_id, Transform2D.IDENTITY)

func add_component(entity_id: int, component_value: Transform2D) -> void:
	var chunk: ECSComponentTransform2DArrayChunk = get_or_create_chunk(entity_id)
	chunk.add_component(entity_id, component_value)

func remove_component(entity_id: int) -> void:
	var chunk: ECSComponentTransform2DArrayChunk = get_chunk(entity_id)
	if chunk != null:
		var slot: int = ECSEntityIdsUtils.slot_from_handle(entity_id)
		chunk.remove_component(slot)

func set_component(entity_id: int, component_value: Transform2D) -> void:
	var chunk: ECSComponentTransform2DArrayChunk = get_or_create_chunk(entity_id)
	chunk.set_component(entity_id, component_value)

func get_component(entity_id: int) -> Transform2D:
	var chunk: ECSComponentTransform2DArrayChunk = get_chunk(entity_id)
	if chunk != null:
		return chunk.get_component(entity_id)
	return Transform2D.IDENTITY

func create_chunk() -> ECSComponentTransform2DArrayChunk:
	return ECSComponentTransform2DArrayChunk.new()
