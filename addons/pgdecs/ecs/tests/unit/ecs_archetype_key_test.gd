extends RefCounted
class_name ECSArchetypeKeyTest

func test_different_component_sets_have_different_keys(runner: ECSTestRunner) -> void:
	var key_a: PackedInt64Array = ECSArchetypeKey.make_from_packed_ids(PackedInt64Array([1, 2]))
	var key_b: PackedInt64Array = ECSArchetypeKey.make_from_packed_ids(PackedInt64Array([1, 3]))
	runner.assert_false(ECSArchetypeKey.equals(key_a, key_b))

func test_unsorted_and_duplicate_ids_normalize_to_same_key(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	var normalized: PackedInt64Array = ecs._normalize_component_ids(PackedInt64Array([3, 1, 2, 1]))
	var key_a: PackedInt64Array = ECSArchetypeKey.make_from_packed_ids(normalized)
	var key_b: PackedInt64Array = ECSArchetypeKey.make_from_packed_ids(PackedInt64Array([1, 2, 3]))
	runner.assert_true(ECSArchetypeKey.equals(key_a, key_b))
	runner.assert_eq(normalized, PackedInt64Array([1, 2, 3]))

func test_distinct_archetypes_with_same_bit_hash(runner: ECSTestRunner) -> void:
	const POSITION_ID: int = 1
	const HEALTH_ID: int = 2
	const TAG_ID: int = 3
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	ecs.register_component(HEALTH_ID, TYPE_PACKED_INT32_ARRAY)
	ecs.register_component(TAG_ID, TYPE_PACKED_INT32_ARRAY)
	var mask_ab: ECSBitMask = ECSBitMask.new(4)
	mask_ab.bit_set(POSITION_ID, true)
	mask_ab.bit_set(HEALTH_ID, true)
	var mask_c: ECSBitMask = ECSBitMask.new(4)
	mask_c.bit_set(TAG_ID, true)
	if mask_ab.bit_hash() == mask_c.bit_hash():
		runner.assert_false(mask_ab.bit_equals(mask_c))
	var e_ab: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID, HEALTH_ID]))
	var e_c: int = ecs.create_entity_packed(PackedInt64Array([TAG_ID]))
	var arch_ab: ECSArchetype = ecs.get_entity_archetype(e_ab)
	var arch_c: ECSArchetype = ecs.get_entity_archetype(e_c)
	runner.assert_not_null(arch_ab)
	runner.assert_not_null(arch_c)
	runner.assert_false(arch_ab == arch_c)
	runner.assert_true(ecs.has_component(e_ab, POSITION_ID))
	runner.assert_true(ecs.has_component(e_ab, HEALTH_ID))
	runner.assert_false(ecs.has_component(e_ab, TAG_ID))
	runner.assert_true(ecs.has_component(e_c, TAG_ID))
	runner.assert_false(ecs.has_component(e_c, POSITION_ID))

func test_bit_equals_detects_different_masks(runner: ECSTestRunner) -> void:
	var mask_a: ECSBitMask = ECSBitMask.new(4)
	mask_a.bit_set(1, true)
	var mask_b: ECSBitMask = ECSBitMask.new(4)
	mask_b.bit_set(2, true)
	runner.assert_false(mask_a.bit_equals(mask_b))
	mask_b.bit_set(1, true)
	runner.assert_false(mask_a.bit_equals(mask_b))
	mask_a.bit_set(2, true)
	runner.assert_true(mask_a.bit_equals(mask_b))

func test_hash_packed_ids_stable_for_same_key(runner: ECSTestRunner) -> void:
	var key: PackedInt64Array = PackedInt64Array([1, 2, 3])
	var hash_a: int = ECSArchetypeKey.hash_packed_ids(key)
	var hash_b: int = ECSArchetypeKey.hash_packed_ids(key.duplicate())
	runner.assert_eq(hash_a, hash_b)

func test_hash_packed_ids_differs_for_different_keys(runner: ECSTestRunner) -> void:
	var key_a: PackedInt64Array = PackedInt64Array([1, 2])
	var key_b: PackedInt64Array = PackedInt64Array([1, 3])
	runner.assert_false(ECSArchetypeKey.hash_packed_ids(key_a) == ECSArchetypeKey.hash_packed_ids(key_b))
