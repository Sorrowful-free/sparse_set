class_name ECSVisualRegistryStrategy extends Resource

## Стратегия visual registry: @export-параметры + фабрика.
## [param host] — опциональный [ECSVisualHost] с дочернего [ECSWorld]; null без сцены.
@export var enabled: bool = true

func create_registry(
	_ecs: ECSManager,
	_world: ECSWorld,
	_host: ECSVisualHost = null,
) -> ECSVisualRegistry:
	push_error("ECSVisualRegistryStrategy.create_registry: override in subclass")
	return null
