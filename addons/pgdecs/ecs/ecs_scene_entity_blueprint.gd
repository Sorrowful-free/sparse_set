@abstract
class_name ECSSceneEntityBlueprint extends Node

## Scene-маркер одной ECS-сущности. Маркер должен быть дочерним узлом source_node.
## В отличие от ECSEntityBlueprint, наследуется от Node и читает scene-значения напрямую.

@abstract func build_component_ids() -> PackedInt64Array

## Статические дефолты { component_id: value }.
func build_default_values() -> Dictionary:
	return {}

## Создаёт одну ECS-сущность из маркера и его узла-источника в общем bootstrap buffer.
func spawn_from_scene(buf: ECSCommandBuffer, source_node: Node) -> int:
	var entity_id: int = buf.create_entity_packed(build_component_ids())
	apply_defaults(buf, entity_id, source_node)
	return entity_id

## Применяет статические дефолты. Переопределения могут вызвать super и записать
## scene-derived значения из source_node через тот же command buffer.
func apply_defaults(buf: ECSCommandBuffer, entity_id: int, _source_node: Node) -> void:
	var defaults: Dictionary = build_default_values()
	for component_id: Variant in defaults:
		buf.set_component(entity_id, int(component_id), defaults[component_id])
