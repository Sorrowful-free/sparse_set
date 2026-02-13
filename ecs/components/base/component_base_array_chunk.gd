@abstract class_name ComponentBaseArrayChunk extends RefCounted

var _entity_ids: PackedInt32Array

func _init() -> void:
	_entity_ids = PackedInt32Array()

func get_size() -> int:
	return _entity_ids.size()

func get_entity_ids() -> PackedInt32Array:
	return _entity_ids

## Освобождает слот по индексу (записывает значение по умолчанию для типа). Вызывается из ComponentBaseArray.remove_entity.
@abstract func remove_component(index: int) -> void

## Проверяет, есть ли в чанке данные для сущности. Вызывается из ComponentBaseArray.has_entity.
@abstract func has_component(entity_id: int) -> bool

func clear() -> void:
	_entity_ids.clear()
