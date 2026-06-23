extends RefCounted
class_name ECSCommandBufferTest

const POSITION_ID: int = 1

func test_create_entity_via_buffer(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	var buf: ECSCommandBuffer = ECSCommandBuffer.new(ecs)
	var component_ids: PackedInt64Array = PackedInt64Array([POSITION_ID])
	var temp_id: int = buf.create_entity(component_ids)
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
	var cids: PackedInt64Array = PackedInt64Array([POSITION_ID])
	var temp_id: int = buf.create_entity(cids)
	buf.execute()
	var ids: PackedInt64Array = ECSQueryBuilder.new().with_component(POSITION_ID).build(ecs).get_entity_ids()
	runner.assert_eq(ids.size(), 1)
	var pos: ECSComponentVector2Array = ecs.get_component_array(POSITION_ID) as ECSComponentVector2Array
	pos.set_component(ids[0], Vector2(1.0, 2.0))
	runner.assert_eq(pos.get_component(ids[0]), Vector2(1.0, 2.0))
