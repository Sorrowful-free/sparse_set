extends RefCounted
class_name ECSArchetypeGcTest

const POSITION_ID: int = 1
const HEALTH_ID: int = 2
const TAG_ID: int = 3

func _make_ecs() -> ECSManager:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	ecs.register_component(HEALTH_ID, TYPE_PACKED_INT32_ARRAY)
	ecs.register_component(TAG_ID, TYPE_PACKED_INT32_ARRAY)
	return ecs

func test_destroy_all_evicts_archetypes_after_flush(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = _make_ecs()
	var e1: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	var e2: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID, HEALTH_ID]))
	runner.assert_eq(ecs.count_live_archetypes(), 2)
	ecs.destroy_entity(e1)
	ecs.destroy_entity(e2)
	runner.assert_eq(ecs.count_live_archetypes(), 0)
	runner.assert_gt(ecs.count_registered_archetypes(), 0)
	ecs.flush_archetype_gc()
	runner.assert_eq(ecs.count_registered_archetypes(), 0)

func test_auto_gc_false_requires_manual_flush(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = _make_ecs()
	ecs.auto_gc_archetypes = false
	var eid: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	ecs.destroy_entity(eid)
	runner.assert_eq(ecs.count_live_archetypes(), 0)
	runner.assert_eq(ecs.count_registered_archetypes(), 1)
	ecs.gc_empty_archetypes()
	runner.assert_eq(ecs.count_registered_archetypes(), 0)

func test_add_remove_component_reuses_archetype_key(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = _make_ecs()
	var eid: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	ecs.add_component(eid, HEALTH_ID)
	var arch_with_health: ECSArchetype = ecs.get_entity_archetype(eid)
	ecs.remove_component(eid, HEALTH_ID)
	var arch_pos_only: ECSArchetype = ecs.get_entity_archetype(eid)
	runner.assert_not_null(arch_pos_only)
	ecs.add_component(eid, HEALTH_ID)
	var arch_restored: ECSArchetype = ecs.get_entity_archetype(eid)
	runner.assert_not_null(arch_restored)
	runner.assert_eq(arch_restored._component_ids, PackedInt64Array([POSITION_ID, HEALTH_ID]))
	ecs.flush_archetype_gc()

func test_reset_clears_world_but_keeps_components(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = _make_ecs()
	ecs.create_entities_packed(10, PackedInt64Array([POSITION_ID]))
	runner.assert_gt(ecs.count_live_archetypes(), 0)
	ecs.reset()
	runner.assert_eq(ecs.count_live_archetypes(), 0)
	runner.assert_not_null(ecs.get_component_array(POSITION_ID))
	var new_id: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	runner.assert_true(ecs.is_alive(new_id))

func test_churn_archetypes_stays_bounded(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = _make_ecs()
	var peak_live: int = 0
	for i in range(200):
		var eid: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
		if i % 2 == 0:
			ecs.add_component(eid, HEALTH_ID)
		if i % 3 == 0:
			ecs.add_component(eid, TAG_ID)
		ecs.destroy_entity(eid)
		peak_live = maxi(peak_live, ecs.count_live_archetypes())
	runner.assert_eq(ecs.count_live_archetypes(), 0)
	runner.assert_true(peak_live <= 8)
	ecs.flush_archetype_gc()
	runner.assert_eq(ecs.count_registered_archetypes(), 0)

func test_empty_archetype_chunk_removed_from_map(runner: ECSTestRunner) -> void:
	var bits: PackedInt64Array = PackedInt64Array([1])
	var arch: ECSArchetype = ECSArchetype.new(bits, PackedInt64Array([1]))
	var entity: int = ECSEntityHandle.make(5000, 1)
	arch.add_entity(entity)
	runner.assert_eq(arch.get_chunk_indices().size(), 1)
	arch.remove_entity(entity)
	runner.assert_eq(arch.get_chunk_indices().size(), 0)
	runner.assert_eq(arch.get_live_count(), 0)
