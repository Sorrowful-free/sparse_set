extends RefCounted
class_name ECSQueryTest

const POSITION_ID: int = 1
const HEALTH_ID: int = 2
const TAG_ID: int = 3

func test_query_match_all(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	ecs.register_component(HEALTH_ID, TYPE_PACKED_INT32_ARRAY)
	var with_pos: int = ecs.create_entity(POSITION_ID)
	var with_both: int = ecs.create_entity(POSITION_ID, HEALTH_ID)
	var query: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).with_component(HEALTH_ID).build(ecs)
	runner.assert_false(query.match(with_pos))
	runner.assert_true(query.match(with_both))

func test_query_without(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	ecs.register_component(TAG_ID, TYPE_PACKED_INT32_ARRAY)
	var only_pos: int = ecs.create_entity(POSITION_ID)
	var pos_and_tag: int = ecs.create_entity(POSITION_ID, TAG_ID)
	var q: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).without_component(TAG_ID).build(ecs)
	runner.assert_true(q.match(only_pos))
	runner.assert_false(q.match(pos_and_tag))

func test_get_entity_ids(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	ecs.register_component(HEALTH_ID, TYPE_PACKED_INT32_ARRAY)
	var tmp = ecs.create_entity(POSITION_ID)
	var e2: int = ecs.create_entity(POSITION_ID, HEALTH_ID)
	var e3: int = ecs.create_entity(POSITION_ID, HEALTH_ID)
	var query: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).with_component(HEALTH_ID).build(ecs)
	var ids: PackedInt64Array = query.get_entity_ids()
	runner.assert_eq(ids.size(), 2)
	runner.assert_true(ids.find(e2) >= 0)
	runner.assert_true(ids.find(e3) >= 0)

## get_chunks() возвращает те же сущности, что и get_entity_ids(); итерация по чанкам даёт тот же набор.
func test_get_chunks_same_entities_as_get_entity_ids(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	ecs.register_component(HEALTH_ID, TYPE_PACKED_INT32_ARRAY)
	ecs.create_entity(POSITION_ID)
	var e2: int = ecs.create_entity(POSITION_ID, HEALTH_ID)
	var e3: int = ecs.create_entity(POSITION_ID, HEALTH_ID)
	var query: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).with_component(HEALTH_ID).build(ecs)
	var from_ids: PackedInt64Array = query.get_entity_ids()
	var from_chunks: PackedInt64Array = PackedInt64Array()
	for chunk in query.get_chunks():
		var ids: PackedInt64Array = chunk.get_entity_ids()
		for i in range(ids.size()):
			if ids[i] >= 0:
				from_chunks.append(ids[i])
	runner.assert_eq(from_chunks.size(), from_ids.size())
	runner.assert_true(from_chunks.find(e2) >= 0)
	runner.assert_true(from_chunks.find(e3) >= 0)

## Итерация строго по чанкам: get_entity_count() и get_entity_id_at() согласованы.
func test_get_chunks_iterate_by_chunk(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	ecs.register_component(HEALTH_ID, TYPE_PACKED_INT32_ARRAY)
	var created: PackedInt64Array = ecs.create_entities(5, POSITION_ID, HEALTH_ID)
	var query: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).with_component(HEALTH_ID).build(ecs)
	var chunks: Array[ECSQueryChunk] = query.get_chunks()
	runner.assert_gt(chunks.size(), 0)
	var total: int = 0
	for chunk in chunks:
		var qc: ECSQueryChunk = chunk as ECSQueryChunk
		runner.assert_not_null(qc)
		var count: int = qc.get_entity_count()
		var by_slot: int = 0
		for i in range(qc.get_size()):
			if qc.get_entity_id_at(i) >= 0:
				by_slot += 1
		runner.assert_eq(count, by_slot)
		total += count
	runner.assert_eq(total, created.size())
