class_name ECSQueryChunk extends RefCounted

## Один чанк результата запроса: вид на PackedInt64Array entity_id из архетипа.
## Пустые слоты в чанке помечены entity_id == -1.

var _entity_ids: PackedInt64Array
var _ecs_manager: ECSManager
var _chunk_index: int

func _init(entity_ids_chunk: PackedInt64Array, ecs_manager: ECSManager, chunk_index: int) -> void:
	_entity_ids = entity_ids_chunk
	_ecs_manager = ecs_manager
	_chunk_index = chunk_index

func get_chunk_index() -> int:
	return _chunk_index

func get_size() -> int:
	return _entity_ids.size()

func get_entity_count() -> int:
	var entity_count: int = 0
	for i in range(_entity_ids.size()):
		if _entity_ids[i] >= 0:
			entity_count += 1
	return entity_count

func get_entity_id_at(slot_index: int) -> int:
	if slot_index < 0 || slot_index >= _entity_ids.size():
		return -1
	return _entity_ids[slot_index]

func get_entity_ids() -> PackedInt64Array:
	return _entity_ids

func get_component_chunk(component_id: int) -> ECSComponentBaseArrayChunk:
	var comp_array: ECSComponentBaseArray = _ecs_manager.get_component_array(component_id)
	if comp_array == null:
		return null
	return comp_array.get_chunk_by_index(_chunk_index)
