#THAT FILE WAS GENERATED PLEASE DONOT CHANGE IT

class_name ECSComponentCollisionPolygon3DArray extends ECSComponentBaseArray

func add_entity(entity_id: int) -> void:
	var chunk: ECSComponentCollisionPolygon3DArrayChunk = get_or_create_chunk(entity_id)
	chunk.add_component(entity_id, null)

func add_component(entity_id: int, component_value: CollisionPolygon3D) -> void:
	var chunk: ECSComponentCollisionPolygon3DArrayChunk = get_or_create_chunk(entity_id)
	chunk.add_component(entity_id, component_value)

func remove_component(entity_id: int) -> void:
	var chunk: ECSComponentCollisionPolygon3DArrayChunk = get_chunk(entity_id)
	if chunk != null:
		var slot: int = ECSEntityIdsUtils.slot_from_handle(entity_id)
		chunk.remove_component(slot)

func set_component(entity_id: int, component_value: CollisionPolygon3D) -> void:
	var chunk: ECSComponentCollisionPolygon3DArrayChunk = get_or_create_chunk(entity_id)
	chunk.set_component(entity_id, component_value)

func get_component(entity_id: int) -> CollisionPolygon3D:
	var chunk: ECSComponentCollisionPolygon3DArrayChunk = get_chunk(entity_id)
	if chunk != null:
		return chunk.get_component(entity_id)
	return null

func create_chunk() -> ECSComponentCollisionPolygon3DArrayChunk:
	return ECSComponentCollisionPolygon3DArrayChunk.new()
