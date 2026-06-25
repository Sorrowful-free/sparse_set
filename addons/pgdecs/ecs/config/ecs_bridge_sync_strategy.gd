class_name ECSBridgeSyncStrategy extends ECSSystemStrategy

## Одна sync-система на [member bridge_type]; частота через [member run_group] / hz группы.
@export var bridge_type: int = 0

func create_system(ecs: ECSManager, world: ECSWorld = null) -> ECSSystemBase:
	if world == null:
		return null
	return ECSBridgeSyncSystem.new(ecs, world, bridge_type)
