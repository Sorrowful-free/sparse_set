extends GutTest
class_name ECSManagerArchetypeTransitionTest

const POSITION_ID: int = 1
const HEALTH_ID: int = 2
const TAG_ID: int = 3

func test_create_entity_normalizes_unsorted_and_duplicate_ids() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	ecs.register_component(HEALTH_ID, TYPE_PACKED_INT32_ARRAY)
	var e1: int = ecs.create_entity_packed(PackedInt64Array([HEALTH_ID, POSITION_ID, HEALTH_ID]))
	var e2: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID, HEALTH_ID]))
	assert_true(ecs.has_component(e1, POSITION_ID))
	assert_true(ecs.has_component(e1, HEALTH_ID))
	var a1: ECSArchetype = ecs.get_entity_archetype(e1)
	var a2: ECSArchetype = ecs.get_entity_archetype(e2)
	assert_not_null(a1)
	assert_true(a1 == a2)
	assert_eq(a1._component_ids, PackedInt64Array([POSITION_ID, HEALTH_ID]))

func test_add_remove_reuses_archetype_via_transition_cache() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	ecs.register_component(HEALTH_ID, TYPE_PACKED_INT32_ARRAY)
	var e_a: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	var e_b: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	ecs.add_component(e_a, HEALTH_ID)
	var arch_after_add_a: ECSArchetype = ecs.get_entity_archetype(e_a)
	ecs.add_component(e_b, HEALTH_ID)
	var arch_after_add_b: ECSArchetype = ecs.get_entity_archetype(e_b)
	assert_true(arch_after_add_a == arch_after_add_b)
	ecs.remove_component(e_a, HEALTH_ID)
	var arch_after_remove_a: ECSArchetype = ecs.get_entity_archetype(e_a)
	ecs.remove_component(e_b, HEALTH_ID)
	var arch_after_remove_b: ECSArchetype = ecs.get_entity_archetype(e_b)
	assert_true(arch_after_remove_a == arch_after_remove_b)
	assert_true(arch_after_remove_a == ecs.get_entity_archetype(e_a))

func test_add_component_idempotent_for_same_archetype() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	ecs.register_component(HEALTH_ID, TYPE_PACKED_INT32_ARRAY)
	var eid: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID, HEALTH_ID]))
	var before: ECSArchetype = ecs.get_entity_archetype(eid)
	ecs.add_component(eid, HEALTH_ID)
	var after: ECSArchetype = ecs.get_entity_archetype(eid)
	assert_true(before == after)

func test_precache_with_unsorted_ids_matches_create() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	ecs.register_component(TAG_ID, TYPE_PACKED_INT32_ARRAY)
	ecs.precache_archetype_packed(PackedInt64Array([TAG_ID, POSITION_ID, TAG_ID]))
	var eid: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID, TAG_ID]))
	assert_true(ecs.has_component(eid, POSITION_ID))
	assert_true(ecs.has_component(eid, TAG_ID))
