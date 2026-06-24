class_name ECSComponentRegistryConfig extends Resource

## id тегов (enum-as-int в наследнике игры).
@export var tags: Array[int] = []
## component_id (int) → storage_type (Variant.Type как int).
@export var components: Dictionary = {}

func apply_to(ecs: ECSManager) -> void:
	for tag_id: int in tags:
		ecs.register_tag(tag_id)
	for component_id: Variant in components:
		ecs.register_component(int(component_id), int(components[component_id]))
