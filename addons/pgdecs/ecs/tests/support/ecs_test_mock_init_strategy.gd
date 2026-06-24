class_name ECSTestMockInitStrategy extends ECSSystemInitStrategy

func create_system(ecs: ECSManager, _world: ECSWorld = null) -> ECSSystemBase:
	return ECSTestCountSystem.new(ecs)
