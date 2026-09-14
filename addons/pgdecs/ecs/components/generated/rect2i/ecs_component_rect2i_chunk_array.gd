#THAT FILE WAS GENERATED PLEASE DONOT CHANGE IT

class_name ECSComponentRect2iArrayChunk extends ECSComponentBaseArrayChunk

var _components_values: Array[Rect2i]

func _init() -> void:
	super()
	_components_values = []
	_components_values.resize(ECSEntityIdsUtils.CHUNK_SIZE)
	_components_values.fill(Rect2i())

func add_component(entity_id: int, component_value: Rect2i) -> void:
	var slot: int = ECSEntityIdsUtils.slot_from_handle(entity_id)
	_components_values[slot] = component_value
	_value_version += 1

func remove_component(index: int) -> void:
	_components_values[index] = Rect2i()
	_value_version += 1

func remove_components_batch(indices: PackedInt32Array) -> void:
	for idx in indices:
		_components_values[idx] = Rect2i()
	_value_version += 1

func add_components_batch(entity_ids: PackedInt64Array) -> void:
	for entity_id in entity_ids:
		var slot: int = ECSEntityIdsUtils.slot_from_handle(entity_id)
		_components_values[slot] = Rect2i()
	_value_version += 1

func set_component(entity_id: int, component_value: Rect2i) -> void:
	set_value_at_slot(ECSEntityIdsUtils.slot_from_handle(entity_id), component_value)

func get_component(entity_id: int) -> Rect2i:
	return get_value_at_slot(ECSEntityIdsUtils.slot_from_handle(entity_id))

func get_value_at_slot(slot_index: int) -> Rect2i:
	return _components_values[slot_index]

func get_values_buffer() -> Array[Rect2i]:
	return _components_values

func set_value_at_slot(slot_index: int, component_value: Rect2i) -> void:
	_components_values[slot_index] = component_value
	_value_version += 1

func clear() -> void:
	_components_values.fill(Rect2i())
	_value_version += 1
