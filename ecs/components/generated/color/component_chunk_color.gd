class_name ComponentChunkColor extends ComponentChunkBase

var _components_values: PackedColorArray

func _init(capacity: int) -> void:
	super (capacity)
	_components_values = PackedColorArray()
	_components_values.resize(capacity)
	
func add_component(entity_id: int, component_value: Color) -> void:
	var index: int = _sparse_set.add(entity_id)
	_components_values[index] = component_value

func remove_component(entity_id: int) -> void:
	var index: int = _sparse_set.take_index(entity_id)
	_sparse_set.remove(entity_id)
	_components_values[index] = Color.BLACK
	
func has_component(entity_id: int) -> bool:
	return _sparse_set.has(entity_id)

func set_component(entity_id: int, component_value: Color) -> void:
	var index: int = _sparse_set.add(entity_id)
	_components_values[index] = component_value

func get_component(entity_id: int) -> Color:
	var index: int = _sparse_set.take(entity_id)
	return _components_values[index]

func clear() -> void:
	super.clear()
	_components_values.clear()
