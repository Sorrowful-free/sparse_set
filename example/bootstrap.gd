extends Node
class_name Bootstrap

var _ecs: ECSManager = ECSManager.new()
var _components: GameComponents

func _ready() -> void:
	_components = GameComponents.new(_ecs)
	var entity_id: int = _ecs.create_entity(GameComponents.POSITION_COMPONENT_ID)
	_components.PositionComponent.set_component(entity_id, Vector2(100.0, 200.0))

func _process(_delta: float) -> void:
	pass
