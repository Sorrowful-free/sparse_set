@abstract
class_name ECSComponentRegistryStrategy extends Resource

## Стратегия регистрации схемы ECS: теги и component_id → storage type.
## Переопределите [method get_tags] и [method get_components] в игре (enum, @export, кастомная логика).
@export var enabled: bool = true

@abstract func get_tags() -> Array[int]

@abstract func get_components() -> Dictionary[int, ECSComponent.Type]

func apply_to(ecs: ECSManager) -> void:
	for tag_id: int in get_tags():
		ecs.register_tag(tag_id)
	var components: Dictionary[int, ECSComponent.Type] = get_components()
	for component_id: int in components:
		ecs.register_component(component_id, components[component_id])
