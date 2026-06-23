#THAT FILE WAS GENERATED PLEASE DONOT CHANGE IT

class_name ECSComponentVector4ArrayChunk extends ECSComponentBaseArrayChunk

var _components_values: PackedVector4Array

func _init() -> void:
	super()
	_components_values = PackedVector4Array()
	_components_values.resize(ECSEntityIdsUtils.CHUNK_SIZE)
	_components_values.fill(Vector4.ZERO)

func add_component(entity_id: int, component_value: Vector4) -> void:
	var slot: int = ECSEntityIdsUtils.slot_from_handle(entity_id)
	_components_values[slot] = component_value

func remove_component(index: int) -> void:
	_components_values[index] = Vector4.ZERO

func remove_components_batch(indices: PackedInt32Array) -> void:
	for idx in indices:
		_components_values[idx] = Vector4.ZERO

func add_components_batch(entity_ids: PackedInt64Array) -> void:
	for entity_id in entity_ids:
		var slot: int = ECSEntityIdsUtils.slot_from_handle(entity_id)
		_components_values[slot] = Vector4.ZERO

func set_component(entity_id: int, component_value: Vector4) -> void:
	set_value_at_slot(ECSEntityIdsUtils.slot_from_handle(entity_id), component_value)

func get_component(entity_id: int) -> Vector4:
	return get_value_at_slot(ECSEntityIdsUtils.slot_from_handle(entity_id))

func get_value_at_slot(slot_index: int) -> Vector4:
	return _components_values[slot_index]

func set_value_at_slot(slot_index: int, component_value: Vector4) -> void:
	_components_values[slot_index] = component_value

func clear() -> void:
	_components_values.fill(Vector4.ZERO)
