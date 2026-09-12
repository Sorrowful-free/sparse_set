extends GutTest
class_name ECSTagTest

const POSITION_ID: int = 1
const ENEMY_TAG_ID: int = 10

func test_register_tag_and_create_with_data() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	ecs.register_tag(ENEMY_TAG_ID)
	var eid: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID, ENEMY_TAG_ID]))
	assert_true(ecs.has_component(eid, POSITION_ID))
	assert_true(ecs.has_component(eid, ENEMY_TAG_ID))
	assert_true(ecs.is_tag(ENEMY_TAG_ID))
	assert_null(ecs.get_component_array(ENEMY_TAG_ID))

func test_tag_only_entity() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_tag(ENEMY_TAG_ID)
	var eid: int = ecs.create_entity_packed(PackedInt64Array([ENEMY_TAG_ID]))
	assert_true(ecs.has_component(eid, ENEMY_TAG_ID))
	assert_null(ecs.get_component_array(ENEMY_TAG_ID))

func test_query_with_without_tag() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	ecs.register_tag(ENEMY_TAG_ID)
	var e_plain: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	var e_tagged: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID, ENEMY_TAG_ID]))
	var q_enemy: ECSQuery = ECSQueryBuilder.new().with_component(ENEMY_TAG_ID).build(ecs)
	var ids: PackedInt64Array = q_enemy.get_entity_ids()
	assert_eq(ids.size(), 1)
	assert_eq(ids[0], e_tagged)
	var q_no_enemy: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).without_component(ENEMY_TAG_ID).build(ecs)
	ids = q_no_enemy.get_entity_ids()
	assert_eq(ids.size(), 1)
	assert_eq(ids[0], e_plain)

func test_add_remove_tag_preserves_data() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	ecs.register_tag(ENEMY_TAG_ID)
	var pos: ECSComponentVector2Array = ecs.get_component_array(POSITION_ID) as ECSComponentVector2Array
	var eid: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	pos.set_component(eid, Vector2(3.0, 4.0))
	ecs.add_component(eid, ENEMY_TAG_ID)
	assert_true(ecs.has_component(eid, ENEMY_TAG_ID))
	assert_eq(pos.get_component(eid), Vector2(3.0, 4.0))
	ecs.remove_component(eid, ENEMY_TAG_ID)
	assert_false(ecs.has_component(eid, ENEMY_TAG_ID))
	assert_eq(pos.get_component(eid), Vector2(3.0, 4.0))

func test_destroy_entity_with_tag() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	ecs.register_tag(ENEMY_TAG_ID)
	var eid: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID, ENEMY_TAG_ID]))
	ecs.destroy_entity(eid)
	assert_false(ecs.has_component(eid, POSITION_ID))
	assert_false(ecs.has_component(eid, ENEMY_TAG_ID))

func test_register_conflict_tag_then_component() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_tag(ENEMY_TAG_ID)
	ecs.register_component(ENEMY_TAG_ID, ECSComponent.Type.PACKED_INT32)
	assert_push_error("already registered as tag")
	assert_true(ecs.is_tag(ENEMY_TAG_ID))
	assert_null(ecs.get_component_array(ENEMY_TAG_ID))

func test_register_conflict_component_then_tag() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	ecs.register_tag(POSITION_ID)
	assert_push_error("already registered as component")
	assert_false(ecs.is_tag(POSITION_ID))
	assert_not_null(ecs.get_component_array(POSITION_ID))

func test_command_buffer_add_remove_tag() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	ecs.register_tag(ENEMY_TAG_ID)
	var eid: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	var buf: ECSCommandBuffer = ECSCommandBuffer.new(ecs)
	buf.add_component(eid, ENEMY_TAG_ID)
	buf.execute()
	assert_true(ecs.has_component(eid, ENEMY_TAG_ID))
	buf.remove_component(eid, ENEMY_TAG_ID)
	buf.execute()
	assert_false(ecs.has_component(eid, ENEMY_TAG_ID))

func test_get_component_chunk_returns_null_for_tag() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	ecs.register_tag(ENEMY_TAG_ID)
	ecs.create_entity_packed(PackedInt64Array([POSITION_ID, ENEMY_TAG_ID]))
	var query: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).build(ecs)
	query.for_each_chunk(func(chunk: ECSQueryChunk) -> void:
		assert_null(chunk.get_component_chunk(ENEMY_TAG_ID))
	)
