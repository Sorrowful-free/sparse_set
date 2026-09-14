extends GutTest
class_name ECSRegressionTest

const POSITION_ID: int = 1
const HEALTH_ID: int = 2
const FORBIDDEN_ID: int = 99

func test_query_without_larger_than_archetype_does_not_crash() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	var query: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).without_component(FORBIDDEN_ID).build(ecs)
	assert_eq(query.get_entity_ids().size(), 1)

func test_stale_handle_after_reuse() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	var entity_a: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	ecs.destroy_entity(entity_a)
	ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	assert_false(ecs.is_alive(entity_a))

func test_add_remove_preserves_other_component_values() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	ecs.register_component(HEALTH_ID, ECSComponent.Type.PACKED_INT32)
	var entity_id: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID, HEALTH_ID]))
	var pos: ECSComponentPackedVector2Array = ecs.get_component_array(POSITION_ID) as ECSComponentPackedVector2Array
	var health: ECSComponentPackedInt32Array = ecs.get_component_array(HEALTH_ID) as ECSComponentPackedInt32Array
	pos.set_component(entity_id, Vector2(1.0, 2.0))
	health.set_component(entity_id, 50)
	ecs.remove_component(entity_id, HEALTH_ID)
	ecs.add_component(entity_id, HEALTH_ID)
	assert_eq(pos.get_component(entity_id), Vector2(1.0, 2.0))

func test_stale_slot_not_counted_as_member() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_INT32)
	var entity_id: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	var pos: ECSComponentPackedInt32Array = ecs.get_component_array(POSITION_ID) as ECSComponentPackedInt32Array
	pos.set_component(entity_id, 99)
	ecs.destroy_entity(entity_id)
	var slot: int = ECSEntityIdsUtils.slot_from_handle(entity_id)
	var chunk: ECSComponentPackedInt32ArrayChunk = pos.get_chunk_by_index(0) as ECSComponentPackedInt32ArrayChunk
	if chunk != null:
		assert_eq(chunk.get_value_at_slot(slot), 0)
	assert_false(ecs.has_component(entity_id, POSITION_ID))
