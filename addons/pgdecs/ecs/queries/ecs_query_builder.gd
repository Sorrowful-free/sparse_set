class_name ECSQueryBuilder extends RefCounted

var _with_component_ids: PackedInt64Array
var _without_component_ids: PackedInt64Array

func _init() -> void:
	_with_component_ids = PackedInt64Array()
	_without_component_ids = PackedInt64Array()

func build(ecs_manager: ECSManager) -> ECSQuery:
	var with_component_ids: PackedInt64Array = _sorted_unique(_with_component_ids)
	var without_component_ids: PackedInt64Array = _sorted_unique(_without_component_ids)
	if !with_component_ids.is_empty() && !without_component_ids.is_empty():
		var with_set: Dictionary[int, bool] = {}
		for component_id in with_component_ids:
			with_set[component_id] = true
		var filtered_without: PackedInt64Array = PackedInt64Array()
		for component_id in without_component_ids:
			if !with_set.has(component_id):
				filtered_without.append(component_id)
		without_component_ids = filtered_without
	return ECSQuery.new(ecs_manager, with_component_ids, without_component_ids)

func with_component(component_id: int) -> ECSQueryBuilder:
	_with_component_ids.append(component_id)
	return self

func with_components(component_ids: Array[int]) -> ECSQueryBuilder:
	for component_id in component_ids:
		_with_component_ids.append(component_id)
	return self

func without_component(component_id: int) -> ECSQueryBuilder:
	_without_component_ids.append(component_id)
	return self

func without_components(component_ids: Array[int]) -> ECSQueryBuilder:
	for component_id in component_ids:
		_without_component_ids.append(component_id)
	return self

func _sorted_unique(component_ids: PackedInt64Array) -> PackedInt64Array:
	if component_ids.is_empty():
		return PackedInt64Array()
	var sorted_ids: PackedInt64Array = component_ids.duplicate()
	sorted_ids.sort()
	var unique_ids: PackedInt64Array = PackedInt64Array()
	var has_prev: bool = false
	var prev: int = 0
	for component_id in sorted_ids:
		if !has_prev || component_id != prev:
			unique_ids.append(component_id)
			prev = component_id
			has_prev = true
	return unique_ids
