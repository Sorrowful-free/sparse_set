extends RefCounted

class_name GameComponents

const POSITION_COMPONENT_ID: int = 1

var _ecs_manager: ECSManager
var PositionComponent: ComponentVector2Array

func _init(ecs_manager: ECSManager) -> void:
	_ecs_manager = ecs_manager
	_ecs_manager.register_component(POSITION_COMPONENT_ID, TYPE_PACKED_VECTOR2_ARRAY)
	PositionComponent = _ecs_manager.get_component_array(POSITION_COMPONENT_ID) as ComponentVector2Array
