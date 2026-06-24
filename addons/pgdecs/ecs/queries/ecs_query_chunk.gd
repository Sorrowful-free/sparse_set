class_name ECSQueryChunk extends RefCounted

## Один чанк результата запроса: вид на ECSArchetypeChunk архетипа.

var _archetype_chunk: ECSArchetypeChunk
var _ecs_manager: ECSManager
var _chunk_index: int

func _init(archetype_chunk: ECSArchetypeChunk, ecs_manager: ECSManager, chunk_index: int) -> void:
	reset(archetype_chunk, ecs_manager, chunk_index)

func reset(archetype_chunk: ECSArchetypeChunk, ecs_manager: ECSManager, chunk_index: int) -> void:
	_archetype_chunk = archetype_chunk
	_ecs_manager = ecs_manager
	_chunk_index = chunk_index

func get_chunk_index() -> int:
	return _chunk_index

func get_archetype_chunk() -> ECSArchetypeChunk:
	return _archetype_chunk

## Число слотов в чанке (обычно CHUNK_SIZE). Для итерации предпочитайте get_entity_count().
func get_size() -> int:
	return ECSEntityIdsUtils.CHUNK_SIZE

func get_entity_count() -> int:
	return _archetype_chunk.get_entity_count()

## Плотный список handle. Читать только [0, get_entity_count()).
func get_dense_entities() -> PackedInt64Array:
	return _archetype_chunk.get_dense_entities()

## Handle по индексу в плотном списке [0..get_entity_count()).
func get_entity_id_at(dense_index: int) -> int:
	return _archetype_chunk.get_dense_entity_at(dense_index)

## Устаревший slot-based вид. Для отладки; в hot path используйте get_dense_entities().
func get_entity_ids() -> PackedInt64Array:
	return _archetype_chunk.get_slots()

func get_component_chunk(component_id: int) -> ECSComponentBaseArrayChunk:
	var comp_array: ECSComponentBaseArray = _ecs_manager.get_component_array(component_id)
	if comp_array == null:
		return null
	return comp_array.get_chunk_by_index(_chunk_index)

func get_structural_version() -> int:
	return _archetype_chunk.get_structural_version()

func get_component_version(component_id: int) -> int:
	var comp_array: ECSComponentBaseArray = _ecs_manager.get_component_array(component_id)
	if comp_array == null:
		return 0
	var chunk: ECSComponentBaseArrayChunk = comp_array.get_chunk_by_index(_chunk_index)
	if chunk == null:
		return 0
	return chunk.get_value_version()
