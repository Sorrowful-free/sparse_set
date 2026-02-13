@abstract class_name ECSComponentBaseArrayChunk extends RefCounted

var _entity_ids: PackedInt32Array

func _init() -> void:
	_entity_ids = PackedInt32Array()

func get_size() -> int:
	return _entity_ids.size()

func get_entity_ids() -> PackedInt32Array:
	return _entity_ids

## Освобождает слот по индексу (записывает значение по умолчанию для типа). Вызывается из ECSComponentBaseArray.remove_entity.
@abstract func remove_component(index: int) -> void

## Батч: освобождает слоты по индексам. Вызывается из ECSComponentBaseArray.remove_entities_batch.
@abstract func remove_components_batch(indices: PackedInt32Array) -> void

## Батч: добавляет сущности в чанк с дефолтным значением. entity_ids должны относиться к этому чанку.
@abstract func add_components_batch(entity_ids: PackedInt64Array) -> void

## Проверяет, есть ли в чанке данные для сущности. Вызывается из ECSComponentBaseArray.has_entity.
@abstract func has_component(entity_id: int) -> bool

func clear() -> void:
	_entity_ids.clear()
