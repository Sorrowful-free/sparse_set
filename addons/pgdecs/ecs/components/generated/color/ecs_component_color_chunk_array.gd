#THAT FILE WAS GENERATED PLEASE DONOT CHANGE IT

class_name ECSComponentColorArrayChunk extends ECSComponentBaseArrayChunk

var _components_values: PackedColorArray

func _init() -> void:
	super()
	_components_values = PackedColorArray()
	_components_values.resize(ECSEntityIdsUtils.CHUNK_SIZE)
	_components_values.fill(Color.BLACK)

func add_component(entity_id: int, component_value: Color) -> void:
	var slot: int = ECSEntityIdsUtils.slot_from_handle(entity_id)
	_components_values[slot] = component_value

func remove_component(index: int) -> void:
	_components_values[index] = Color.BLACK

func remove_components_batch(indices: PackedInt32Array) -> void:
	for idx in indices:
		_components_values[idx] = Color.BLACK

func add_components_batch(entity_ids: PackedInt64Array) -> void:
	for entity_id in entity_ids:
		var slot: int = ECSEntityIdsUtils.slot_from_handle(entity_id)
		_components_values[slot] = Color.BLACK

func set_component(entity_id: int, component_value: Color) -> void:
	set_value_at_slot(ECSEntityIdsUtils.slot_from_handle(entity_id), component_value)

func get_component(entity_id: int) -> Color:
	return get_value_at_slot(ECSEntityIdsUtils.slot_from_handle(entity_id))

func get_value_at_slot(slot_index: int) -> Color:
	return _components_values[slot_index]

func set_value_at_slot(slot_index: int, component_value: Color) -> void:
	_components_values[slot_index] = component_value

func clear() -> void:
	_components_values.fill(Color.BLACK)
