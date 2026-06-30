class_name ExampleReleaseIntentStrategy extends ECSSystemStrategy

@export var dependencies: ExampleEcsDependencies

func create_system(ecs: ECSManager, _world: ECSWorld = null) -> ECSSystemBase:
	if dependencies == null:
		return null
	var system := ExampleReleaseIntentSystem.new(ecs, dependencies)
	system.run_group = run_group
	return system
