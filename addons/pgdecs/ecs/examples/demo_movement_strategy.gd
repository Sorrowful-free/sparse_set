class_name DemoMovementStrategy extends ECSSystemStrategy

@export var speed_multiplier: float = 1.0

func create_system(ecs: ECSManager, _world: ECSWorld = null) -> ECSSystemBase:
	return DemoMovementSystem.new(ecs, speed_multiplier)
