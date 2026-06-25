extends ECSBridgeBackendStrategy
class_name ECSExampleMockBridgeBackendStrategy

## Пример backend strategy: один bridge_type, один слот host.
@export var slot: StringName = &"units"

func create_backend(host: ECSBridgeHost, _ecs: ECSManager, _world: ECSWorld) -> ECSBridgeBackend:
	if host == null:
		return null
	# Игра: return UnitsMultiMeshBridge.new(host.require_slot(slot))
	return null
