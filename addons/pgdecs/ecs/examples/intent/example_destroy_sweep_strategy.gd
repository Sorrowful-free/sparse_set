class_name ExampleDestroySweepStrategy extends ECSSystemStrategy

func create_system(ecs: ECSManager, _world: ECSWorld = null) -> ECSSystemBase:
	var system := ExampleDestroySweepSystem.new(ecs)
	system.run_group = run_group
	return system
