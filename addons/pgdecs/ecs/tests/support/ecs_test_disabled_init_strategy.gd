class_name ECSTestDisabledInitStrategy extends ECSSystemInitStrategy

func _init() -> void:
	enabled = false

func create_system(ecs: ECSManager, _world: ECSWorld = null) -> ECSSystemBase:
	return ECSTestCountSystem.new(ecs)
