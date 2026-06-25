class_name ECSBridgeOrchestratorStrategy extends ECSSystemStrategy

## Strategy для [ECSBridgeOrchestratorSystem]: pending acquire/release. Component ids — из [ECSBridgeRegistry].
@export var destroy_on_release: bool = true

func create_system(ecs: ECSManager, world: ECSWorld = null) -> ECSSystemBase:
	if world == null:
		return null
	return ECSBridgeOrchestratorSystem.new(ecs, world, destroy_on_release)
