@abstract
class_name ECSBridgeBackendStrategy extends Resource

## Одна strategy = один bridge_type + фабрика backend. Список — в [ECSBridgeRegistryStrategy.backend_strategies].
@export var enabled: bool = true
@export var bridge_type: int = 0

@abstract
func create_backend(
	host: ECSBridgeHost,
	_ecs: ECSManager,
	_world: ECSWorld,
) -> ECSBridgeBackend
