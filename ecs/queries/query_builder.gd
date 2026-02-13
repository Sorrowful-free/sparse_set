class_name QueryBuilder extends RefCounted

var _with_component_ids: PackedInt64Array
var _without_component_ids: PackedInt64Array

func _init() -> void:
	_with_component_ids = PackedInt64Array()
	_without_component_ids = PackedInt64Array()

func build(ecs_manager: ECSManager) -> Query:
	return Query.new(ecs_manager, _with_component_ids, _without_component_ids)

func with_component(component_id: int) -> QueryBuilder:
	_with_component_ids.append(component_id)
	return self

func without_component(component_id: int) -> QueryBuilder:
	_without_component_ids.append(component_id)
	return self
