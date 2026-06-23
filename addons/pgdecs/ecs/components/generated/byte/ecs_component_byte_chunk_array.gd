#THAT FILE WAS GENERATED PLEASE DONOT CHANGE IT

class_name ECSComponentByteArrayChunk extends ECSComponentBaseArrayChunk

var _components_values: PackedByteArray
var _count: int = 0

func _init() -> void:
	super()
	_entity_ids.resize(ECSEntityIdsUtils.CHUNK_SIZE)
	_entity_ids.fill(-1)
	_components_values = PackedByteArray()
	_components_values.resize(ECSEntityIdsUtils.CHUNK_SIZE)
	_components_values.fill(0)

func add_component(entity_id: int, component_value: int) -> void:
	var entity_index: int = ECSEntityHandle.index_of(entity_id)
	var index: int = ECSEntityIdsUtils.get_chunk_entity_index(entity_index)
	if _entity_ids[index] == -1:
		_count += 1
	_entity_ids[index] = entity_id
	_components_values[index] = component_value

func remove_component(index: int) -> void:
	if _entity_ids[index] != -1:
		_count -= 1
	_entity_ids[index] = -1
	_components_values[index] = 0

func remove_components_batch(indices: PackedInt32Array) -> void:
	for idx in indices:
		if _entity_ids[idx] != -1:
			_count -= 1
		_entity_ids[idx] = -1
		_components_values[idx] = 0

func add_components_batch(entity_ids: PackedInt64Array) -> void:
	for entity_id in entity_ids:
		var entity_index: int = ECSEntityHandle.index_of(entity_id)
		var index: int = ECSEntityIdsUtils.get_chunk_entity_index(entity_index)
		if _entity_ids[index] == -1:
			_count += 1
		_entity_ids[index] = entity_id
		_components_values[index] = 0

func has_component(entity_id: int) -> bool:
	var entity_index: int = ECSEntityHandle.index_of(entity_id)
	var index: int = ECSEntityIdsUtils.get_chunk_entity_index(entity_index)
	return _entity_ids[index] == entity_id

func set_component(entity_id: int, component_value: int) -> void:
	var entity_index: int = ECSEntityHandle.index_of(entity_id)
	var index: int = ECSEntityIdsUtils.get_chunk_entity_index(entity_index)
	_components_values[index] = component_value

func get_component(entity_id: int) -> int:
	var entity_index: int = ECSEntityHandle.index_of(entity_id)
	var index: int = ECSEntityIdsUtils.get_chunk_entity_index(entity_index)
	return _components_values[index]

func get_entity_count() -> int:
	return _count

func clear() -> void:
	_entity_ids.fill(-1)
	_components_values.fill(0)
	_count = 0
