@abstract
class_name ECSSystemStrategy extends Resource

## Стратегия системы: @export-параметры + фабрика RefCounted-системы.
## Stateless: только export-поля; runtime не сериализуется.
@export var enabled: bool = true

@abstract func create_system(_ecs: ECSManager, _world: ECSWorld = null) -> ECSSystemBase
