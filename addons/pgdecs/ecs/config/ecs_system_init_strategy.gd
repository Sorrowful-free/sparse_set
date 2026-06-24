class_name ECSSystemInitStrategy extends Resource

## Стратегия инициализации: @export-параметры + фабрика RefCounted-системы.
## Stateless: только export-поля; runtime не сериализуется.
@export var enabled: bool = true

func create_system(_ecs: ECSManager, _world: ECSWorld = null) -> ECSSystemBase:
	push_error("ECSSystemInitStrategy.create_system: override in subclass")
	return null
