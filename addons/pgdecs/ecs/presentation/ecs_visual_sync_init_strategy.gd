class_name ECSVisualSyncInitStrategy extends ECSSystemInitStrategy

func create_system(ecs: ECSManager, world: ECSWorld = null) -> ECSSystemBase:
	if world == null or world.get_visual_registry() == null:
		push_error("ECSVisualSyncInitStrategy: world with visual registry required")
		return null
	return ECSVisualSyncSystem.new(ecs, world.get_visual_registry())
