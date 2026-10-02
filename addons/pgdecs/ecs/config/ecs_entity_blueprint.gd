@abstract
class_name ECSEntityBlueprint extends Resource

## Абстрактный blueprint сущности: набор component_id (int) + инициализация значений.
## Игра наследует Resource, в [method build_component_ids] возвращает id из своего enum
## (тот же int, что в [ECSComponentRegistryStrategy]).
##
## Spawn и параметры — **только** через [ECSCommandBuffer]:
## create + [method ECSCommandBuffer.set_component] в одном буфере, затем [method ECSCommandBuffer.execute].
## В системе execute делает [ECSSystemRunner]; при bootstrap — свой буфер + execute.

## Нормализованный набор component id (без тегов-only если не нужны в архетипе).
@abstract func build_component_ids() -> PackedInt64Array

## Статические дефолты { component_id: value } для [method apply_defaults].
## Переопредели для простых констант; для сложной логики — [method apply_defaults].
func build_default_values() -> Dictionary:
	return {}

## Batch: create_entities_packed + [method apply_instance] на каждый temp id в том же буфере.
func spawn_batch(buf: ECSCommandBuffer, count: int) -> PackedInt64Array:
	if count <= 0:
		return PackedInt64Array()
	var entity_ids: PackedInt64Array = buf.create_entities_packed(count, build_component_ids())
	apply_instances(buf, entity_ids)
	return entity_ids

## Одна сущность; temp id до execute.
func spawn_one(buf: ECSCommandBuffer) -> int:
	var entity_id: int = buf.create_entity(build_component_ids())
	apply_defaults(buf, entity_id)
	return entity_id

func apply_instances(buf: ECSCommandBuffer, entity_ids: PackedInt64Array) -> void:
	for i in range(entity_ids.size()):
		var entity_id: int = entity_ids[i]
		if entity_id != 0:
			apply_defaults(buf, entity_id)

## Общие дефолты: [method build_default_values] → [method ECSCommandBuffer.set_component].
## Переопредели для доп. логики; вызови [code]super.apply_defaults[/code] чтобы сохранить dict.
func apply_defaults(buf: ECSCommandBuffer, entity_id: int) -> void:
	var defaults: Dictionary = build_default_values()
	for component_id: Variant in defaults:
		buf.set_component(entity_id, int(component_id), defaults[component_id])
