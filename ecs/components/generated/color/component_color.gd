class_name ComponentColor extends ComponentBase


func _init(component_capacity: int, chunk_capacity: int) -> void:
	super (component_capacity, chunk_capacity)

func add_component(entity_id: int, component_value: Color) -> void:
	var chunk: ComponentChunkColor = get_or_create_chunk(entity_id)
	var chunk_entity_index: int = EntityIdsUtils.get_chunk_entity_index(entity_id, _chunk_capacity)
	chunk.add_component(chunk_entity_index, component_value)
	_entities_ids.add(entity_id)

func remove_component(entity_id: int) -> void:
	_entities_ids.remove(entity_id)

	var chunk: ComponentChunkColor = get_chunk(entity_id)
	if chunk != null:
		var chunk_entity_index: int = EntityIdsUtils.get_chunk_entity_index(entity_id, _chunk_capacity)
		chunk.remove_component(chunk_entity_index)
		if chunk.get_size() == 0:
			_chunks.erase(chunk)

func has_component(entity_id: int) -> bool:
	var chunk: ComponentChunkColor = get_chunk(entity_id)
	if chunk == null:
		return false
	return chunk.has_component(EntityIdsUtils.get_chunk_entity_index(entity_id, _chunk_capacity))

func set_component(entity_id: int, component_value: Color) -> void:
	var chunk: ComponentChunkColor = get_or_create_chunk(entity_id)
	var chunk_entity_index: int = EntityIdsUtils.get_chunk_entity_index(entity_id, _chunk_capacity)
	chunk.set_component(chunk_entity_index, component_value)

func get_component(entity_id: int) -> Color:
	var chunk: ComponentChunkColor = get_chunk(entity_id)
	if (chunk != null):
		var chunk_entity_index: int = EntityIdsUtils.get_chunk_entity_index(entity_id, _chunk_capacity)
		return chunk.get_component(chunk_entity_index)
	return Color.BLACK

func create_chunk(capacity: int) -> ComponentChunkColor:
	return ComponentChunkColor.new(capacity)
