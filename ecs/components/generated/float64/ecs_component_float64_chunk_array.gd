#THAT FILE WAS GENERATED PLEASE DONOT CHANGE IT

class_name ECSComponentFloat64ArrayChunk extends ECSComponentBaseArrayChunk

var _components_values: PackedFloat64Array
var _count: int = 0

func _init() -> void:
	super()
	_entity_ids.resize(ECSEntityIdsUtils.CHUNK_SIZE)
	_entity_ids.fill(-1)
	_components_values = PackedFloat64Array()
	_components_values.resize(ECSEntityIdsUtils.CHUNK_SIZE)
	_components_values.fill(0.0)

func add_component(entity_id: int, component_value: float) -> void:
	var index: int = ECSEntityIdsUtils.get_chunk_entity_index(entity_id)
	if _entity_ids[index] == -1:
		_count += 1
	_entity_ids[index] = entity_id
	_components_values[index] = component_value

func remove_component(index: int) -> void:
	if _entity_ids[index] != -1:
		_count -= 1
	_entity_ids[index] = -1
	_components_values[index] = 0.0

func remove_components_batch(indices: PackedInt32Array) -> void:
	for idx in indices:
		if _entity_ids[idx] != -1:
			_count -= 1
		_entity_ids[idx] = -1
		_components_values[idx] = 0.0

func add_components_batch(entity_ids: PackedInt64Array) -> void:
	for entity_id in entity_ids:
		var index: int = ECSEntityIdsUtils.get_chunk_entity_index(entity_id)
		if _entity_ids[index] == -1:
			_count += 1
		_entity_ids[index] = entity_id
		_components_values[index] = 0.0

func has_component(entity_id: int) -> bool:
	var index: int = ECSEntityIdsUtils.get_chunk_entity_index(entity_id)
	return _entity_ids[index] == entity_id

func set_component(entity_id: int, component_value: float) -> void:
	var index: int = ECSEntityIdsUtils.get_chunk_entity_index(entity_id)
	_components_values[index] = component_value

func get_component(entity_id: int) -> float:
	var index: int = ECSEntityIdsUtils.get_chunk_entity_index(entity_id)
	return _components_values[index]

func get_size() -> int:
	return _count

func clear() -> void:
	_entity_ids.fill(-1)
	_components_values.fill(0.0)
	_count = 0
