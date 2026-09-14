#THAT FILE WAS GENERATED PLEASE DONOT CHANGE IT

class_name ECSComponentProjectionArray extends ECSComponentBaseArray

func add_entity(entity_id: int) -> void:
	var chunk: ECSComponentProjectionArrayChunk = get_or_create_chunk(entity_id)
	chunk.add_component(entity_id, Projection())

func add_component(entity_id: int, component_value: Projection) -> void:
	var chunk: ECSComponentProjectionArrayChunk = get_or_create_chunk(entity_id)
	chunk.add_component(entity_id, component_value)

func remove_component(entity_id: int) -> void:
	var chunk: ECSComponentProjectionArrayChunk = get_chunk(entity_id)
	if chunk != null:
		var slot: int = ECSEntityIdsUtils.slot_from_handle(entity_id)
		chunk.remove_component(slot)

func set_component(entity_id: int, component_value: Projection) -> void:
	var chunk: ECSComponentProjectionArrayChunk = get_or_create_chunk(entity_id)
	chunk.set_component(entity_id, component_value)

func get_component(entity_id: int) -> Projection:
	var chunk: ECSComponentProjectionArrayChunk = get_chunk(entity_id)
	if chunk != null:
		return chunk.get_component(entity_id)
	return Projection()

func create_chunk() -> ECSComponentProjectionArrayChunk:
	return ECSComponentProjectionArrayChunk.new()
