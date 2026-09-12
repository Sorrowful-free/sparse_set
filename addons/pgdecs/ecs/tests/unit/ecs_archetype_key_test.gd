extends GutTest
class_name ECSArchetypeKeyTest

func test_different_component_sets_have_different_keys() -> void:
	var key_a: PackedInt64Array = ECSArchetypeKey.make_from_packed_ids(PackedInt64Array([1, 2]))
	var key_b: PackedInt64Array = ECSArchetypeKey.make_from_packed_ids(PackedInt64Array([1, 3]))
	assert_false(ECSArchetypeKey.equals(key_a, key_b))

func test_unsorted_and_duplicate_ids_normalize_to_same_key() -> void:
	var ecs: ECSManager = ECSManager.new()
	var normalized: PackedInt64Array = ecs._normalize_component_ids(PackedInt64Array([3, 1, 2, 1]))
	var key_a: PackedInt64Array = ECSArchetypeKey.make_from_packed_ids(normalized)
	var key_b: PackedInt64Array = ECSArchetypeKey.make_from_packed_ids(PackedInt64Array([1, 2, 3]))
	assert_true(ECSArchetypeKey.equals(key_a, key_b))
	assert_eq(normalized, PackedInt64Array([1, 2, 3]))

func test_distinct_archetypes_with_same_bit_hash() -> void:
	const POSITION_ID: int = 1
	const HEALTH_ID: int = 2
	const TAG_ID: int = 3
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	ecs.register_component(HEALTH_ID, ECSComponent.Type.PACKED_INT32)
	ecs.register_component(TAG_ID, ECSComponent.Type.PACKED_INT32)
	var mask_ab: ECSBitMask = ECSBitMask.new(4)
	mask_ab.bit_set(POSITION_ID, true)
	mask_ab.bit_set(HEALTH_ID, true)
	var mask_c: ECSBitMask = ECSBitMask.new(4)
	mask_c.bit_set(TAG_ID, true)
	if mask_ab.bit_hash() == mask_c.bit_hash():
		assert_false(mask_ab.bit_equals(mask_c))
	var e_ab: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID, HEALTH_ID]))
	var e_c: int = ecs.create_entity_packed(PackedInt64Array([TAG_ID]))
	var arch_ab: ECSArchetype = ecs.get_entity_archetype(e_ab)
	var arch_c: ECSArchetype = ecs.get_entity_archetype(e_c)
	assert_not_null(arch_ab)
	assert_not_null(arch_c)
	assert_false(arch_ab == arch_c)
	assert_true(ecs.has_component(e_ab, POSITION_ID))
	assert_true(ecs.has_component(e_ab, HEALTH_ID))
	assert_false(ecs.has_component(e_ab, TAG_ID))
	assert_true(ecs.has_component(e_c, TAG_ID))
	assert_false(ecs.has_component(e_c, POSITION_ID))

func test_bit_equals_detects_different_masks() -> void:
	var mask_a: ECSBitMask = ECSBitMask.new(4)
	mask_a.bit_set(1, true)
	var mask_b: ECSBitMask = ECSBitMask.new(4)
	mask_b.bit_set(2, true)
	assert_false(mask_a.bit_equals(mask_b))
	mask_b.bit_set(1, true)
	assert_false(mask_a.bit_equals(mask_b))
	mask_a.bit_set(2, true)
	assert_true(mask_a.bit_equals(mask_b))

func test_hash_packed_ids_stable_for_same_key() -> void:
	var key: PackedInt64Array = PackedInt64Array([1, 2, 3])
	var hash_a: int = ECSArchetypeKey.hash_packed_ids(key)
	var hash_b: int = ECSArchetypeKey.hash_packed_ids(key.duplicate())
	assert_eq(hash_a, hash_b)

func test_hash_packed_ids_differs_for_different_keys() -> void:
	var key_a: PackedInt64Array = PackedInt64Array([1, 2])
	var key_b: PackedInt64Array = PackedInt64Array([1, 3])
	assert_false(ECSArchetypeKey.hash_packed_ids(key_a) == ECSArchetypeKey.hash_packed_ids(key_b))
