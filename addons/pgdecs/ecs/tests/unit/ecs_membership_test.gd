extends RefCounted
class_name ECSMembershipTest

const POSITION_ID: int = 1
const HEALTH_ID: int = 2

func test_has_component_via_archetype_only(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	ecs.register_component(HEALTH_ID, TYPE_PACKED_INT32_ARRAY)
	var entity_id: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	runner.assert_true(ecs.has_component(entity_id, POSITION_ID))
	runner.assert_false(ecs.has_component(entity_id, HEALTH_ID))

func test_destroy_clears_membership(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	var entity_id: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	ecs.destroy_entity(entity_id)
	runner.assert_false(ecs.has_component(entity_id, POSITION_ID))

func test_has_component_false_for_stale_handle_after_destroy(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	var entity_id: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	runner.assert_true(ecs.has_component(entity_id, POSITION_ID))
	ecs.destroy_entity(entity_id)
	runner.assert_false(ecs.is_alive(entity_id))
	runner.assert_false(ecs.has_component(entity_id, POSITION_ID))
