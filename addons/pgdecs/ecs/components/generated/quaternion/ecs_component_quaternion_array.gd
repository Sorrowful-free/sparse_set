#THAT FILE WAS GENERATED PLEASE DONOT CHANGE IT

class_name ECSComponentQuaternionArray extends ECSComponentBaseArray

func add_entity(entity_id: int) -> void:
	var chunk: ECSComponentQuaternionArrayChunk = get_or_create_chunk(entity_id)
	chunk.add_component(entity_id, Quaternion.IDENTITY)

func add_component(entity_id: int, component_value: Quaternion) -> void:
	var chunk: ECSComponentQuaternionArrayChunk = get_or_create_chunk(entity_id)
	chunk.add_component(entity_id, component_value)

func remove_component(entity_id: int) -> void:
	var chunk: ECSComponentQuaternionArrayChunk = get_chunk(entity_id)
	if chunk != null:
		var slot: int = ECSEntityIdsUtils.slot_from_handle(entity_id)
		chunk.remove_component(slot)

func set_component(entity_id: int, component_value: Quaternion) -> void:
	var chunk: ECSComponentQuaternionArrayChunk = get_or_create_chunk(entity_id)
	chunk.set_component(entity_id, component_value)

func get_component(entity_id: int) -> Quaternion:
	var chunk: ECSComponentQuaternionArrayChunk = get_chunk(entity_id)
	if chunk != null:
		return chunk.get_component(entity_id)
	return Quaternion.IDENTITY

func create_chunk() -> ECSComponentQuaternionArrayChunk:
	return ECSComponentQuaternionArrayChunk.new()
