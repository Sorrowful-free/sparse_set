class_name Query extends RefCounted


var _components_bitmask: BitMask
var _without_components_bitmask: BitMask

var _component_ids: PackedInt64Array
var _without_component_ids: PackedInt64Array

var _ecs_manager: EcsManager

func _init(ecs_manager: EcsManager, component_ids: PackedInt64Array, without_component_ids: PackedInt64Array) -> void:
    _ecs_manager = ecs_manager
    _component_ids = component_ids
    _without_component_ids = without_component_ids
    _components_bitmask = BitMask.new(component_ids.size())
    _without_components_bitmask = BitMask.new(without_component_ids.size())
    for component_id in component_ids:
        _components_bitmask.bit_set(component_id, true)
    for component_id in without_component_ids:
        _without_components_bitmask.bit_set(component_id, true)

func match(entity_id: int) -> bool:
    # Проверяем наличие обязательных компонентов
    for component_id in _component_ids:
        if !_ecs_manager.has_component(entity_id, component_id):
            return false
    
    # Проверяем отсутствие запрещенных компонентов
    for component_id in _without_component_ids:
        if _ecs_manager.has_component(entity_id, component_id):
            return false
    
    return true
