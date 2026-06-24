extends RefCounted
class_name ECSCommandBufferTest

const POSITION_ID: int = 1

func test_create_entity_via_buffer(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	var buf: ECSCommandBuffer = ECSCommandBuffer.new(ecs)
	var temp_id: int = buf.create_entity([POSITION_ID])
	runner.assert_lt(temp_id, 0)
	buf.execute()
	var q: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).build(ecs)
	runner.assert_eq(q.get_entity_ids().size(), 1)

func test_destroy_via_buffer(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	var real_id: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	var buf: ECSCommandBuffer = ECSCommandBuffer.new(ecs)
	buf.destroy_entity(real_id)
	buf.execute()
	runner.assert_false(ecs.has_component(real_id, POSITION_ID))

func test_create_then_use_in_same_frame(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	var buf: ECSCommandBuffer = ECSCommandBuffer.new(ecs)
	var temp_id: int = buf.create_entity([POSITION_ID])
	buf.execute()
	var ids: PackedInt64Array = ECSQueryBuilder.new().with_component(POSITION_ID).build(ecs).get_entity_ids()
	runner.assert_eq(ids.size(), 1)
	var pos: ECSComponentVector2Array = ecs.get_component_array(POSITION_ID) as ECSComponentVector2Array
	pos.set_component(ids[0], Vector2(1.0, 2.0))
	runner.assert_eq(pos.get_component(ids[0]), Vector2(1.0, 2.0))

func test_coalesce_create_then_destroy_temp(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	var buf: ECSCommandBuffer = ECSCommandBuffer.new(ecs)
	var temp_id: int = buf.create_entity([POSITION_ID])
	buf.destroy_entity(temp_id)
	buf.execute()
	var q: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).build(ecs)
	runner.assert_eq(q.get_entity_ids().size(), 0)

func test_coalesce_add_remove_same_component(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	const HEALTH_ID: int = 2
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	ecs.register_component(HEALTH_ID, TYPE_PACKED_INT32_ARRAY)
	var real_id: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	var buf: ECSCommandBuffer = ECSCommandBuffer.new(ecs)
	buf.add_component(real_id, HEALTH_ID)
	buf.remove_component(real_id, HEALTH_ID)
	buf.execute()
	runner.assert_true(ecs.has_component(real_id, POSITION_ID))
	runner.assert_false(ecs.has_component(real_id, HEALTH_ID))

func test_coalesce_skip_ops_after_destroy(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	const HEALTH_ID: int = 2
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	ecs.register_component(HEALTH_ID, TYPE_PACKED_INT32_ARRAY)
	var real_id: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	var buf: ECSCommandBuffer = ECSCommandBuffer.new(ecs)
	buf.destroy_entity(real_id)
	buf.add_component(real_id, HEALTH_ID)
	buf.execute()
	runner.assert_false(ecs.is_alive(real_id))

func test_coalesce_heavy_frame(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	const HEALTH_ID: int = 2
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	ecs.register_component(HEALTH_ID, TYPE_PACKED_INT32_ARRAY)
	var cycles: int = 32
	var pos_only: PackedInt64Array = PackedInt64Array([POSITION_ID])
	var survivors: PackedInt64Array = PackedInt64Array()
	survivors.resize(cycles)
	for i in range(cycles):
		survivors[i] = ecs.create_entity_packed(pos_only)
	var buf: ECSCommandBuffer = ECSCommandBuffer.new(ecs)
	for i in range(cycles):
		var temp_id: int = buf.create_entity_packed(pos_only)
		buf.destroy_entity(temp_id)
		var eid: int = survivors[i]
		buf.add_component(eid, HEALTH_ID)
		buf.remove_component(eid, HEALTH_ID)
	for i in range(cycles):
		buf.destroy_entity(survivors[i])
	buf.execute()
	runner.assert_eq(
		ECSQueryBuilder.new().with_component(POSITION_ID).build(ecs).get_entity_ids().size(),
		0
	)

func test_coalesce_merge_destroy_entities(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	var id_a: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	var id_b: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	var id_c: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	var buf: ECSCommandBuffer = ECSCommandBuffer.new(ecs)
	buf.destroy_entity(id_a)
	buf.destroy_entity(id_b)
	buf.destroy_entity(id_c)
	buf.execute()
	runner.assert_false(ecs.is_alive(id_a))
	runner.assert_false(ecs.is_alive(id_b))
	runner.assert_false(ecs.is_alive(id_c))
	runner.assert_eq(ECSQueryBuilder.new().with_component(POSITION_ID).build(ecs).get_entity_ids().size(), 0)

func test_destroy_entities_array_api(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	var ids: PackedInt64Array = ecs.create_entities_packed(3, PackedInt64Array([POSITION_ID]))
	var buf: ECSCommandBuffer = ECSCommandBuffer.new(ecs)
	buf.destroy_entities([ids[0], ids[1], ids[2]])
	buf.execute()
	runner.assert_eq(ECSQueryBuilder.new().with_component(POSITION_ID).build(ecs).get_entity_ids().size(), 0)
