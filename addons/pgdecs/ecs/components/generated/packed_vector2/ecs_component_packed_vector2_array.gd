#THAT FILE WAS GENERATED PLEASE DONOT CHANGE IT

class_name ECSComponentPackedVector2Array extends ECSComponentBaseArray

func add_entity(entity_id: int) -> void:
	var chunk: ECSComponentPackedVector2ArrayChunk = get_or_create_chunk(entity_id)
	chunk.add_component(entity_id, Vector2.ZERO)

func add_component(entity_id: int, component_value: Vector2) -> void:
	var chunk: ECSComponentPackedVector2ArrayChunk = get_or_create_chunk(entity_id)
	chunk.add_component(entity_id, component_value)

func remove_component(entity_id: int) -> void:
	var chunk: ECSComponentPackedVector2ArrayChunk = get_chunk(entity_id)
	if chunk != null:
		var slot: int = ECSEntityIdsUtils.slot_from_handle(entity_id)
		chunk.remove_component(slot)

func set_component(entity_id: int, component_value: Vector2) -> void:
	var chunk: ECSComponentPackedVector2ArrayChunk = get_or_create_chunk(entity_id)
	chunk.set_component(entity_id, component_value)

func get_component(entity_id: int) -> Vector2:
	var chunk: ECSComponentPackedVector2ArrayChunk = get_chunk(entity_id)
	if chunk != null:
		return chunk.get_component(entity_id)
	return Vector2.ZERO

func create_chunk() -> ECSComponentPackedVector2ArrayChunk:
	return ECSComponentPackedVector2ArrayChunk.new()
