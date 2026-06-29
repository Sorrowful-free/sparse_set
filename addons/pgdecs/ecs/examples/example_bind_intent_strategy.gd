class_name ExampleBindIntentStrategy extends ECSSystemStrategy

@export var services: ExampleEcsServices

func create_system(ecs: ECSManager, _world: ECSWorld = null) -> ECSSystemBase:
	if services == null:
		return null
	var system := ExampleBindIntentSystem.new(ecs, services)
	system.run_group = run_group
	return system
