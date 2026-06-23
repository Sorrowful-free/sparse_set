extends RefCounted
class_name ECSWorldStateTest

## Юнит-тесты на валидность состояния ECS-мира: несколько компонентов, разные комбинации,
## проверка что запросы возвращают ровно те сущности, которые подходят под with/without.

const POSITION_ID: int = 1
const HEALTH_ID: int = 2
const TAG_ID: int = 3

func _sorted_ids(ids: PackedInt64Array) -> PackedInt64Array:
	var arr: Array[int] = []
	for i in range(ids.size()):
		arr.append(ids[i])
	arr.sort()
	var out: PackedInt64Array = PackedInt64Array()
	for x in arr:
		out.append(x)
	return out

func _assert_query_ids(runner: ECSTestRunner, query: ECSQuery, expected: Array[int]) -> void:
	var result: PackedInt64Array = query.get_entity_ids()
	var expected_packed: PackedInt64Array = PackedInt64Array()
	for e in expected:
		expected_packed.append(e)
	runner.assert_eq(_sorted_ids(result).size(), expected_packed.size(), "query size")
	var sorted_result: PackedInt64Array = _sorted_ids(result)
	var sorted_expected: PackedInt64Array = _sorted_ids(expected_packed)
	for i in range(sorted_expected.size()):
		runner.assert_eq(sorted_result[i], sorted_expected[i], "query id at %d" % i)


func test_three_components_queries_return_correct_entities(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	ecs.register_component(HEALTH_ID, TYPE_PACKED_INT32_ARRAY)
	ecs.register_component(TAG_ID, TYPE_PACKED_INT32_ARRAY)

	var e_pos_only: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	var e_health_only: int = ecs.create_entity_packed(PackedInt64Array([HEALTH_ID]))
	var e_pos_health: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID, HEALTH_ID]))
	var e_pos_tag: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID, TAG_ID]))
	var e_all: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID, HEALTH_ID, TAG_ID]))

	# With Position -> e_pos_only, e_pos_health, e_pos_tag, e_all
	var q_pos: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).build(ecs)
	_assert_query_ids(runner, q_pos, [e_pos_only, e_pos_health, e_pos_tag, e_all])

	# With Health -> e_health_only, e_pos_health, e_all
	var q_health: ECSQuery = ECSQueryBuilder.new().with_component(HEALTH_ID).build(ecs)
	_assert_query_ids(runner, q_health, [e_health_only, e_pos_health, e_all])

	# With Position AND Health -> e_pos_health, e_all
	var q_pos_health: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).with_component(HEALTH_ID).build(ecs)
	_assert_query_ids(runner, q_pos_health, [e_pos_health, e_all])

	# With Position WITHOUT Tag -> e_pos_only, e_pos_health
	var q_pos_no_tag: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).without_component(TAG_ID).build(ecs)
	_assert_query_ids(runner, q_pos_no_tag, [e_pos_only, e_pos_health])

	# With Position WITHOUT Health -> e_pos_only, e_pos_tag
	var q_pos_no_health: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).without_component(HEALTH_ID).build(ecs)
	_assert_query_ids(runner, q_pos_no_health, [e_pos_only, e_pos_tag])

	# With all three -> only e_all
	var q_all: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).with_component(HEALTH_ID).with_component(TAG_ID).build(ecs)
	_assert_query_ids(runner, q_all, [e_all])

	# With Tag only -> e_pos_tag, e_all
	var q_tag: ECSQuery = ECSQueryBuilder.new().with_component(TAG_ID).build(ecs)
	_assert_query_ids(runner, q_tag, [e_pos_tag, e_all])


func test_queries_after_destroy(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	ecs.register_component(HEALTH_ID, TYPE_PACKED_INT32_ARRAY)

	var e1: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	var e2: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID, HEALTH_ID]))
	var e3: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID, HEALTH_ID]))

	var q_both: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).with_component(HEALTH_ID).build(ecs)
	_assert_query_ids(runner, q_both, [e2, e3])

	ecs.destroy_entity(e2)
	_assert_query_ids(runner, q_both, [e3])

	ecs.destroy_entity(e3)
	_assert_query_ids(runner, q_both, [])

	var q_pos: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).build(ecs)
	_assert_query_ids(runner, q_pos, [e1])


func test_queries_after_add_remove_component(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	ecs.register_component(HEALTH_ID, TYPE_PACKED_INT32_ARRAY)

	var e: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	var q_pos: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).build(ecs)
	var q_both: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).with_component(HEALTH_ID).build(ecs)

	_assert_query_ids(runner, q_pos, [e])
	_assert_query_ids(runner, q_both, [])

	ecs.add_component(e, HEALTH_ID)
	_assert_query_ids(runner, q_pos, [e])
	_assert_query_ids(runner, q_both, [e])

	ecs.remove_component(e, HEALTH_ID)
	_assert_query_ids(runner, q_pos, [e])
	_assert_query_ids(runner, q_both, [])


func test_batch_destroy_queries_stay_valid(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	ecs.register_component(HEALTH_ID, TYPE_PACKED_INT32_ARRAY)

	var ids_both: PackedInt64Array = ecs.create_entities_packed(5, PackedInt64Array([POSITION_ID, HEALTH_ID]))
	var e_pos_only: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))

	var q_both: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).with_component(HEALTH_ID).build(ecs)
	var q_pos: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).build(ecs)

	runner.assert_eq(q_both.get_entity_ids().size(), 5)
	runner.assert_eq(q_pos.get_entity_ids().size(), 6)

	ecs.destroy_entities(ids_both)
	_assert_query_ids(runner, q_both, [])
	_assert_query_ids(runner, q_pos, [e_pos_only])
