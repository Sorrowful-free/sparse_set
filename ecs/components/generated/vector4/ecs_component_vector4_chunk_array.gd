#THAT FILE WAS GENERATED PLEASE DONOT CHANGE IT

class_name ComponentVector4ArrayChunk extends ComponentBaseArrayChunk

var _components_values: PackedVector4Array
var _count: int = 0

func _init() -> void:
	super()
	_entity_ids.resize(EntityIdsUtils.CHUNK_SIZE)
	_entity_ids.fill(-1)
	_components_values = PackedVector4Array()
	_components_values.resize(EntityIdsUtils.CHUNK_SIZE)
	_components_values.fill(Vector4.ZERO)

func add_component(entity_id: int, component_value: Vector4) -> void:
	var index: int = EntityIdsUtils.get_chunk_entity_index(entity_id)
	if _entity_ids[index] == -1:
		_count += 1
	_entity_ids[index] = entity_id
	_components_values[index] = component_value

func remove_component(index: int) -> void:
	if _entity_ids[index] != -1:
		_count -= 1
	_entity_ids[index] = -1
	_components_values[index] = Vector4.ZERO

func has_component(entity_id: int) -> bool:
	var index: int = EntityIdsUtils.get_chunk_entity_index(entity_id)
	return _entity_ids[index] == entity_id

func set_component(entity_id: int, component_value: Vector4) -> void:
	var index: int = EntityIdsUtils.get_chunk_entity_index(entity_id)
	_components_values[index] = component_value

func get_component(entity_id: int) -> Vector4:
	var index: int = EntityIdsUtils.get_chunk_entity_index(entity_id)
	return _components_values[index]

func get_size() -> int:
	return _count

func clear() -> void:
	_entity_ids.fill(-1)
	_components_values.fill(Vector4.ZERO)
	_count = 0
