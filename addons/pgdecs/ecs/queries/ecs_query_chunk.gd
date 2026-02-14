class_name ECSQueryChunk extends RefCounted

## Один чанк результата запроса: вид на PackedInt64Array entity_id из архетипа.
## Позволяет итерироваться строго по чанку и в дальнейшем раздавать чанки разным воркерам.
## Пустые слоты в чанке помечены entity_id == -1.

var _entity_ids: PackedInt64Array
var _ecs_manager: ECSManager

func _init(entity_ids_chunk: PackedInt64Array, ecs_manager: ECSManager) -> void:
	_entity_ids = entity_ids_chunk
	_ecs_manager = ecs_manager

## Размер чанка (число слотов), обычно ECSEntityIdsUtils.CHUNK_SIZE.
func get_size() -> int:
	return _entity_ids.size()

## Число валидных сущностей в чанке (слоты с entity_id >= 0).
func get_entity_count() -> int:
	var n: int = 0
	for i in range(_entity_ids.size()):
		if _entity_ids[i] >= 0:
			n += 1
	return n

## Возвращает entity_id в слоте [slot_index]. Может быть -1 (пустой слот).
func get_entity_id_at(slot_index: int) -> int:
	if slot_index < 0 || slot_index >= _entity_ids.size():
		return -1
	return _entity_ids[slot_index]

## Сырой вид на чанк entity_id (для итерации по слотам 0..get_size()-1).
## Пустые слоты содержат -1.
func get_entity_ids() -> PackedInt64Array:
	return _entity_ids

## Возвращает чанк компонента для этого чанка сущностей (для SoA-итерации).
## Используется любой entity_id из чанка; все сущности в чанке лежат в одном чанке компонента.
## Возвращает null, если в чанке нет валидных сущностей или компонент не зарегистрирован.
func get_component_chunk(component_id: int) -> ECSComponentBaseArrayChunk:
	var entity_id: int = _first_valid_entity_id()
	if entity_id < 0:
		return null
	var comp_array: ECSComponentBaseArray = _ecs_manager.get_component_array(component_id)
	if comp_array == null:
		return null
	return comp_array.get_chunk(entity_id)

func _first_valid_entity_id() -> int:
	for i in range(_entity_ids.size()):
		if _entity_ids[i] >= 0:
			return _entity_ids[i]
	return -1
