#THAT FILE WAS GENERATED PLEASE DONOT CHANGE IT

class_name ECSComponentRect2iArray extends ECSComponentBaseArray

func add_entity(entity_id: int) -> void:
	var chunk: ECSComponentRect2iArrayChunk = get_or_create_chunk(entity_id)
	chunk.add_component(entity_id, Rect2i())

func add_component(entity_id: int, component_value: Rect2i) -> void:
	var chunk: ECSComponentRect2iArrayChunk = get_or_create_chunk(entity_id)
	chunk.add_component(entity_id, component_value)

func remove_component(entity_id: int) -> void:
	var chunk: ECSComponentRect2iArrayChunk = get_chunk(entity_id)
	if chunk != null:
		var slot: int = ECSEntityIdsUtils.slot_from_handle(entity_id)
		chunk.remove_component(slot)

func set_component(entity_id: int, component_value: Rect2i) -> void:
	var chunk: ECSComponentRect2iArrayChunk = get_or_create_chunk(entity_id)
	chunk.set_component(entity_id, component_value)

func get_component(entity_id: int) -> Rect2i:
	var chunk: ECSComponentRect2iArrayChunk = get_chunk(entity_id)
	if chunk != null:
		return chunk.get_component(entity_id)
	return Rect2i()

func create_chunk() -> ECSComponentRect2iArrayChunk:
	return ECSComponentRect2iArrayChunk.new()
