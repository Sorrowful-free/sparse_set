class_name ECSTestMockSystemStrategy extends ECSSystemStrategy

func create_system(ecs: ECSManager, _world: ECSWorld = null) -> ECSSystemBase:
	return ECSTestCountSystem.new(ecs)
