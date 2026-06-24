extends RefCounted
class_name ECSManagerTest

const POSITION_ID: int = 1
const HEALTH_ID: int = 2

func test_register_and_create_entity(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	var eid: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	runner.assert_gt(eid, 0)
	runner.assert_true(ecs.has_component(eid, POSITION_ID))

func test_destroy_entity(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	var eid: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	runner.assert_true(ecs.has_component(eid, POSITION_ID))
	ecs.destroy_entity(eid)
	runner.assert_false(ecs.has_component(eid, POSITION_ID))

func test_add_remove_component(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	ecs.register_component(HEALTH_ID, TYPE_PACKED_INT32_ARRAY)
	var eid: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	runner.assert_false(ecs.has_component(eid, HEALTH_ID))
	ecs.add_component(eid, HEALTH_ID)
	runner.assert_true(ecs.has_component(eid, HEALTH_ID))
	ecs.remove_component(eid, HEALTH_ID)
	runner.assert_false(ecs.has_component(eid, HEALTH_ID))

func test_set_get_component(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	var pos: ECSComponentVector2Array = ecs.get_component_array(POSITION_ID) as ECSComponentVector2Array
	var eid: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	pos.set_component(eid, Vector2(10.0, 20.0))
	runner.assert_eq(pos.get_component(eid), Vector2(10.0, 20.0))

func test_create_entities_batch(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	var ids: PackedInt64Array = ecs.create_entities_packed(10, PackedInt64Array([POSITION_ID]))
	runner.assert_eq(ids.size(), 10)
	for eid in ids:
		runner.assert_true(ecs.has_component(eid, POSITION_ID))

func test_create_entity_array_api(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	ecs.register_component(HEALTH_ID, TYPE_PACKED_INT32_ARRAY)
	var eid: int = ecs.create_entity([POSITION_ID, HEALTH_ID])
	runner.assert_gt(eid, 0)
	runner.assert_true(ecs.has_component(eid, POSITION_ID))
	runner.assert_true(ecs.has_component(eid, HEALTH_ID))

func test_prepare_archetype_hot_path(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	var archetype_ids: PackedInt64Array = ecs.prepare_archetype([POSITION_ID])
	runner.assert_eq(archetype_ids.size(), 1)
	runner.assert_eq(archetype_ids[0], POSITION_ID)
	var e1: int = ecs.create_entity_packed(archetype_ids)
	var e2: int = ecs.create_entity_packed(archetype_ids)
	runner.assert_true(ecs.get_entity_archetype(e1) == ecs.get_entity_archetype(e2))

func test_destroy_entities_batch(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	var ids: PackedInt64Array = ecs.create_entities_packed(5, PackedInt64Array([POSITION_ID]))
	ecs.destroy_entities_packed(ids)
	for eid in ids:
		runner.assert_false(ecs.has_component(eid, POSITION_ID))

func test_destroy_entities_multi_chunk(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	var ids: PackedInt64Array = ecs.create_entities_packed(300, PackedInt64Array([POSITION_ID]))
	var arch: ECSArchetype = ecs.get_entity_archetype(ids[0])
	runner.assert_gt(arch.get_chunks().size(), 1)
	ecs.destroy_entities_packed(ids)
	runner.assert_false(ecs.is_alive(ids[0]))
	runner.assert_false(ecs.is_alive(ids[299]))
	runner.assert_eq(ECSQueryBuilder.new().with_component(POSITION_ID).build(ecs).get_entity_ids().size(), 0)

func test_destroy_entities_array_api(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	var ids: PackedInt64Array = ecs.create_entities_packed(5, PackedInt64Array([POSITION_ID]))
	ecs.destroy_entities([ids[0], ids[1], ids[2], ids[3], ids[4]])
	for eid in ids:
		runner.assert_false(ecs.is_alive(eid))

func test_same_archetype_reused(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	var e1: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	var e2: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	var a1: ECSArchetype = ecs.get_entity_archetype(e1)
	var a2: ECSArchetype = ecs.get_entity_archetype(e2)
	runner.assert_not_null(a1)
	runner.assert_true(a1 == a2)
