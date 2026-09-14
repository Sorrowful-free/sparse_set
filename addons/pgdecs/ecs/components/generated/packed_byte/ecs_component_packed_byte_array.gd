#THAT FILE WAS GENERATED PLEASE DONOT CHANGE IT

class_name ECSComponentPackedByteArray extends ECSComponentBaseArray

func add_entity(entity_id: int) -> void:
	var chunk: ECSComponentPackedByteArrayChunk = get_or_create_chunk(entity_id)
	chunk.add_component(entity_id, 0)

func add_component(entity_id: int, component_value: int) -> void:
	var chunk: ECSComponentPackedByteArrayChunk = get_or_create_chunk(entity_id)
	chunk.add_component(entity_id, component_value)

func remove_component(entity_id: int) -> void:
	var chunk: ECSComponentPackedByteArrayChunk = get_chunk(entity_id)
	if chunk != null:
		var slot: int = ECSEntityIdsUtils.slot_from_handle(entity_id)
		chunk.remove_component(slot)

func set_component(entity_id: int, component_value: int) -> void:
	var chunk: ECSComponentPackedByteArrayChunk = get_or_create_chunk(entity_id)
	chunk.set_component(entity_id, component_value)

func get_component(entity_id: int) -> int:
	var chunk: ECSComponentPackedByteArrayChunk = get_chunk(entity_id)
	if chunk != null:
		return chunk.get_component(entity_id)
	return 0

func create_chunk() -> ECSComponentPackedByteArrayChunk:
	return ECSComponentPackedByteArrayChunk.new()
