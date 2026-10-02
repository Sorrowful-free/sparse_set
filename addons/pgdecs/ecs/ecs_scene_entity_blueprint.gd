@abstract
class_name ECSSceneEntityBlueprint extends Node

## Изолированный scene-маркер одной ECS-сущности.
## В отличие от ECSEntityBlueprint, наследуется от Node и хранит собственные данные сцены.

@abstract func build_component_ids() -> PackedInt64Array

## Статические дефолты { component_id: value }.
func build_default_values() -> Dictionary:
	return {}

## Создаёт одну ECS-сущность из данных этого marker-а в общем bootstrap buffer.
## Переопредели этот метод для собственной логики создания сущности.
func spawn_from_scene(buf: ECSCommandBuffer) -> int:
	var entity_id: int = buf.create_entity_packed(build_component_ids())
	apply_defaults(buf, entity_id)
	return entity_id

## Применяет статические дефолты. Переопределения могут вызвать super и записать
## собственные scene-derived значения marker-а через тот же command buffer.
func apply_defaults(buf: ECSCommandBuffer, entity_id: int) -> void:
	var defaults: Dictionary = build_default_values()
	for component_id: Variant in defaults:
		buf.set_component(entity_id, int(component_id), defaults[component_id])
