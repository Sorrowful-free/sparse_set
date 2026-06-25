extends GutTest
class_name ECSCommandBufferTest

const POSITION_ID: int = 1

func test_create_entity_via_buffer() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	var buf: ECSCommandBuffer = ECSCommandBuffer.new(ecs)
	var temp_id: int = buf.create_entity([POSITION_ID])
	assert_lt(temp_id, 0)
	buf.execute()
	var q: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).build(ecs)
	assert_eq(q.get_entity_ids().size(), 1)

func test_destroy_via_buffer() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	var real_id: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	var buf: ECSCommandBuffer = ECSCommandBuffer.new(ecs)
	buf.destroy_entity(real_id)
	buf.execute()
	assert_false(ecs.has_component(real_id, POSITION_ID))

func test_create_then_set_in_same_frame_before_execute() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	var buf: ECSCommandBuffer = ECSCommandBuffer.new(ecs)
	var temp_id: int = buf.create_entity([POSITION_ID])
	buf.set_component_value(temp_id, POSITION_ID, Vector2(1.0, 2.0))
	buf.execute()
	var ids: PackedInt64Array = ECSQueryBuilder.new().with_component(POSITION_ID).build(ecs).get_entity_ids()
	assert_eq(ids.size(), 1)
	var pos: ECSComponentVector2Array = ecs.get_component_array(POSITION_ID) as ECSComponentVector2Array
	assert_eq(pos.get_component(ids[0]), Vector2(1.0, 2.0))

func test_set_on_temp_skipped_after_create_destroy_coalesce() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	var buf: ECSCommandBuffer = ECSCommandBuffer.new(ecs)
	var temp_id: int = buf.create_entity([POSITION_ID])
	buf.set_component_value(temp_id, POSITION_ID, Vector2(9.0, 9.0))
	buf.destroy_entity(temp_id)
	buf.execute()
	var q: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).build(ecs)
	assert_eq(q.get_entity_ids().size(), 0)

func test_coalesce_set_component_last_wins() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	var buf: ECSCommandBuffer = ECSCommandBuffer.new(ecs)
	var temp_id: int = buf.create_entity([POSITION_ID])
	buf.set_component_value(temp_id, POSITION_ID, Vector2(1.0, 1.0))
	buf.set_component_value(temp_id, POSITION_ID, Vector2(3.0, 4.0))
	buf.execute()
	var ids: PackedInt64Array = ECSQueryBuilder.new().with_component(POSITION_ID).build(ecs).get_entity_ids()
	var pos: ECSComponentVector2Array = ecs.get_component_array(POSITION_ID) as ECSComponentVector2Array
	assert_eq(pos.get_component(ids[0]), Vector2(3.0, 4.0))

func test_create_then_use_in_same_frame() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	var buf: ECSCommandBuffer = ECSCommandBuffer.new(ecs)
	var temp_id: int = buf.create_entity([POSITION_ID])
	buf.execute()
	var ids: PackedInt64Array = ECSQueryBuilder.new().with_component(POSITION_ID).build(ecs).get_entity_ids()
	assert_eq(ids.size(), 1)
	var pos: ECSComponentVector2Array = ecs.get_component_array(POSITION_ID) as ECSComponentVector2Array
	pos.set_component(ids[0], Vector2(1.0, 2.0))
	assert_eq(pos.get_component(ids[0]), Vector2(1.0, 2.0))

func test_coalesce_create_then_destroy_temp() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	var buf: ECSCommandBuffer = ECSCommandBuffer.new(ecs)
	var temp_id: int = buf.create_entity([POSITION_ID])
	buf.destroy_entity(temp_id)
	buf.execute()
	var q: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).build(ecs)
	assert_eq(q.get_entity_ids().size(), 0)

func test_coalesce_add_remove_same_component() -> void:
	var ecs: ECSManager = ECSManager.new()
	const HEALTH_ID: int = 2
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	ecs.register_component(HEALTH_ID, TYPE_PACKED_INT32_ARRAY)
	var real_id: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	var buf: ECSCommandBuffer = ECSCommandBuffer.new(ecs)
	buf.add_component(real_id, HEALTH_ID)
	buf.remove_component(real_id, HEALTH_ID)
	buf.execute()
	assert_true(ecs.has_component(real_id, POSITION_ID))
	assert_false(ecs.has_component(real_id, HEALTH_ID))

func test_coalesce_skip_ops_after_destroy() -> void:
	var ecs: ECSManager = ECSManager.new()
	const HEALTH_ID: int = 2
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	ecs.register_component(HEALTH_ID, TYPE_PACKED_INT32_ARRAY)
	var real_id: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	var buf: ECSCommandBuffer = ECSCommandBuffer.new(ecs)
	buf.destroy_entity(real_id)
	buf.add_component(real_id, HEALTH_ID)
	buf.execute()
	assert_false(ecs.is_alive(real_id))

func test_coalesce_heavy_frame() -> void:
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
	assert_eq(
		ECSQueryBuilder.new().with_component(POSITION_ID).build(ecs).get_entity_ids().size(),
		0
	)

func test_coalesce_merge_destroy_entities() -> void:
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
	assert_false(ecs.is_alive(id_a))
	assert_false(ecs.is_alive(id_b))
	assert_false(ecs.is_alive(id_c))
	assert_eq(ECSQueryBuilder.new().with_component(POSITION_ID).build(ecs).get_entity_ids().size(), 0)

func test_destroy_entities_array_api() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	var ids: PackedInt64Array = ecs.create_entities_packed(3, PackedInt64Array([POSITION_ID]))
	var buf: ECSCommandBuffer = ECSCommandBuffer.new(ecs)
	buf.destroy_entities([ids[0], ids[1], ids[2]])
	buf.execute()
	assert_eq(ECSQueryBuilder.new().with_component(POSITION_ID).build(ecs).get_entity_ids().size(), 0)
