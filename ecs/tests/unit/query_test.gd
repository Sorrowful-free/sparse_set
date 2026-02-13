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
	var query: ECSQuery = ECSECSQueryBuilder.new().with_component(POSITION_ID).with_component(HEALTH_ID).build(ecs)
	runner.assert_false(query.match(with_pos))
	runner.assert_true(query.match(with_both))

func test_query_without(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	ecs.register_component(TAG_ID, TYPE_PACKED_INT32_ARRAY)
	var only_pos: int = ecs.create_entity(POSITION_ID)
	var pos_and_tag: int = ecs.create_entity(POSITION_ID, TAG_ID)
	var q: ECSQuery = ECSECSQueryBuilder.new().with_component(POSITION_ID).without_component(TAG_ID).build(ecs)
	runner.assert_true(q.match(only_pos))
	runner.assert_false(q.match(pos_and_tag))

func test_get_entity_ids(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	ecs.register_component(HEALTH_ID, TYPE_PACKED_INT32_ARRAY)
	var tmp = ecs.create_entity(POSITION_ID)
	var e2: int = ecs.create_entity(POSITION_ID, HEALTH_ID)
	var e3: int = ecs.create_entity(POSITION_ID, HEALTH_ID)
	var query: ECSQuery = ECSECSQueryBuilder.new().with_component(POSITION_ID).with_component(HEALTH_ID).build(ecs)
	var ids: PackedInt64Array = query.get_entity_ids()
	runner.assert_eq(ids.size(), 2)
	runner.assert_true(ids.find(e2) >= 0)
	runner.assert_true(ids.find(e3) >= 0)
