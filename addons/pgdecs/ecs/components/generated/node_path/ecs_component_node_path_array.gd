#THAT FILE WAS GENERATED PLEASE DONOT CHANGE IT

class_name ECSComponentNodePathArray extends ECSComponentBaseArray

func add_entity(entity_id: int) -> void:
	var chunk: ECSComponentNodePathArrayChunk = get_or_create_chunk(entity_id)
	chunk.add_component(entity_id, ^"")

func add_component(entity_id: int, component_value: NodePath) -> void:
	var chunk: ECSComponentNodePathArrayChunk = get_or_create_chunk(entity_id)
	chunk.add_component(entity_id, component_value)

func remove_component(entity_id: int) -> void:
	var chunk: ECSComponentNodePathArrayChunk = get_chunk(entity_id)
	if chunk != null:
		var slot: int = ECSEntityIdsUtils.slot_from_handle(entity_id)
		chunk.remove_component(slot)

func set_component(entity_id: int, component_value: NodePath) -> void:
	var chunk: ECSComponentNodePathArrayChunk = get_or_create_chunk(entity_id)
	chunk.set_component(entity_id, component_value)

func get_component(entity_id: int) -> NodePath:
	var chunk: ECSComponentNodePathArrayChunk = get_chunk(entity_id)
	if chunk != null:
		return chunk.get_component(entity_id)
	return ^""

func create_chunk() -> ECSComponentNodePathArrayChunk:
	return ECSComponentNodePathArrayChunk.new()
