class_name ECSTestDisabledSystemStrategy extends ECSSystemStrategy

func _init() -> void:
	enabled = false

func create_system(_ecs: ECSManager, _world: ECSWorld = null) -> ECSSystemBase:
	push_error("ECSTestDisabledSystemStrategy should not be called")
	return null
