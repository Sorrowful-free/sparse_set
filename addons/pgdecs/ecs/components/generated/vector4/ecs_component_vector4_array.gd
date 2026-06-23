#THAT FILE WAS GENERATED PLEASE DONOT CHANGE IT

class_name ECSComponentVector4Array extends ECSComponentBaseArray

func add_entity(entity_id: int) -> void:
	var chunk: ECSComponentVector4ArrayChunk = get_or_create_chunk(entity_id)
	chunk.add_component(entity_id, Vector4.ZERO)

func add_component(entity_id: int, component_value: Vector4) -> void:
	var chunk: ECSComponentVector4ArrayChunk = get_or_create_chunk(entity_id)
	chunk.add_component(entity_id, component_value)

func remove_component(entity_id: int) -> void:
	var chunk: ECSComponentVector4ArrayChunk = get_chunk(entity_id)
	if chunk != null:
		var slot: int = ECSEntityIdsUtils.slot_from_handle(entity_id)
		chunk.remove_component(slot)

func set_component(entity_id: int, component_value: Vector4) -> void:
	var chunk: ECSComponentVector4ArrayChunk = get_or_create_chunk(entity_id)
	chunk.set_component(entity_id, component_value)

func get_component(entity_id: int) -> Vector4:
	var chunk: ECSComponentVector4ArrayChunk = get_chunk(entity_id)
	if chunk != null:
		return chunk.get_component(entity_id)
	return Vector4.ZERO

func create_chunk() -> ECSComponentVector4ArrayChunk:
	return ECSComponentVector4ArrayChunk.new()
