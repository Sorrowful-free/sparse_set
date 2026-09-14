extends GutTest
class_name ECSManagerTest

const POSITION_ID: int = 1
const HEALTH_ID: int = 2

func test_register_and_create_entity() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	var eid: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	assert_gt(eid, 0)
	assert_true(ecs.has_component(eid, POSITION_ID))

func test_destroy_entity() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	var eid: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	assert_true(ecs.has_component(eid, POSITION_ID))
	ecs.destroy_entity(eid)
	assert_false(ecs.has_component(eid, POSITION_ID))

func test_add_remove_component() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	ecs.register_component(HEALTH_ID, ECSComponent.Type.PACKED_INT32)
	var eid: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	assert_false(ecs.has_component(eid, HEALTH_ID))
	ecs.add_component(eid, HEALTH_ID)
	assert_true(ecs.has_component(eid, HEALTH_ID))
	ecs.remove_component(eid, HEALTH_ID)
	assert_false(ecs.has_component(eid, HEALTH_ID))

func test_set_get_component() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	var pos: ECSComponentPackedVector2Array = ecs.get_component_array(POSITION_ID) as ECSComponentPackedVector2Array
	var eid: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	pos.set_component(eid, Vector2(10.0, 20.0))
	assert_eq(pos.get_component(eid), Vector2(10.0, 20.0))

func test_create_entities_batch() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	var ids: PackedInt64Array = ecs.create_entities_packed(10, PackedInt64Array([POSITION_ID]))
	assert_eq(ids.size(), 10)
	for eid in ids:
		assert_true(ecs.has_component(eid, POSITION_ID))

func test_create_entity_array_api() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	ecs.register_component(HEALTH_ID, ECSComponent.Type.PACKED_INT32)
	var eid: int = ecs.create_entity([POSITION_ID, HEALTH_ID])
	assert_gt(eid, 0)
	assert_true(ecs.has_component(eid, POSITION_ID))
	assert_true(ecs.has_component(eid, HEALTH_ID))

func test_prepare_archetype_hot_path() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	var archetype_ids: PackedInt64Array = ecs.prepare_archetype([POSITION_ID])
	assert_eq(archetype_ids.size(), 1)
	assert_eq(archetype_ids[0], POSITION_ID)
	var e1: int = ecs.create_entity_packed(archetype_ids)
	var e2: int = ecs.create_entity_packed(archetype_ids)
	assert_true(ecs.get_entity_archetype(e1) == ecs.get_entity_archetype(e2))

func test_destroy_entities_batch() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	var ids: PackedInt64Array = ecs.create_entities_packed(5, PackedInt64Array([POSITION_ID]))
	ecs.destroy_entities_packed(ids)
	for eid in ids:
		assert_false(ecs.has_component(eid, POSITION_ID))

func test_destroy_entities_multi_chunk() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	var ids: PackedInt64Array = ecs.create_entities_packed(300, PackedInt64Array([POSITION_ID]))
	var arch: ECSArchetype = ecs.get_entity_archetype(ids[0])
	assert_gt(arch.get_chunks().size(), 1)
	ecs.destroy_entities_packed(ids)
	assert_false(ecs.is_alive(ids[0]))
	assert_false(ecs.is_alive(ids[299]))
	assert_eq(ECSQueryBuilder.new().with_component(POSITION_ID).build(ecs).get_entity_ids().size(), 0)

func test_destroy_entities_array_api() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	var ids: PackedInt64Array = ecs.create_entities_packed(5, PackedInt64Array([POSITION_ID]))
	ecs.destroy_entities([ids[0], ids[1], ids[2], ids[3], ids[4]])
	for eid in ids:
		assert_false(ecs.is_alive(eid))

func test_destroy_entities_multi_archetype() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	ecs.register_component(HEALTH_ID, ECSComponent.Type.PACKED_INT32)
	var pos_only: PackedInt64Array = ecs.create_entities_packed(3, PackedInt64Array([POSITION_ID]))
	var both: PackedInt64Array = ecs.create_entities_packed(2, PackedInt64Array([POSITION_ID, HEALTH_ID]))
	assert_ne(ecs.get_entity_archetype(pos_only[0]), ecs.get_entity_archetype(both[0]))
	var mixed: PackedInt64Array = PackedInt64Array([
		pos_only[0], both[0], pos_only[1], both[1], pos_only[2],
	])
	ecs.destroy_entities_packed(mixed)
	for eid in pos_only:
		assert_false(ecs.is_alive(eid))
	for eid in both:
		assert_false(ecs.is_alive(eid))
	assert_eq(
		ECSQueryBuilder.new().with_component(POSITION_ID).build(ecs).get_entity_ids().size(),
		0
	)

func test_same_archetype_reused() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	var e1: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	var e2: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	var a1: ECSArchetype = ecs.get_entity_archetype(e1)
	var a2: ECSArchetype = ecs.get_entity_archetype(e2)
	assert_not_null(a1)
	assert_true(a1 == a2)
