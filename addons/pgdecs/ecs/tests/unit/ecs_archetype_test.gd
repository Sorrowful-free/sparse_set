extends RefCounted
class_name ECSArchetypeTest

func test_add_has_remove_entity(runner: ECSTestRunner) -> void:
	var bits: PackedInt64Array = PackedInt64Array([1])
	var component_ids: PackedInt64Array = PackedInt64Array([1])
	var arch: ECSArchetype = ECSArchetype.new(bits, component_ids)
	var entity: int = ECSEntityHandle.make(100, 1)
	runner.assert_false(arch.has_entity(entity))
	arch.add_entity(entity)
	runner.assert_true(arch.has_entity(entity))
	arch.remove_entity(entity)
	runner.assert_false(arch.has_entity(entity))

func test_multiple_chunks(runner: ECSTestRunner) -> void:
	var bits: PackedInt64Array = PackedInt64Array([1])
	var component_ids: PackedInt64Array = PackedInt64Array([1])
	var arch: ECSArchetype = ECSArchetype.new(bits, component_ids)
	arch.add_entity(ECSEntityHandle.make(0, 1))
	arch.add_entity(ECSEntityHandle.make(256, 1))
	arch.add_entity(ECSEntityHandle.make(512, 1))
	runner.assert_true(arch.has_entity(ECSEntityHandle.make(0, 1)))
	runner.assert_true(arch.has_entity(ECSEntityHandle.make(256, 1)))
	runner.assert_true(arch.has_entity(ECSEntityHandle.make(512, 1)))
	runner.assert_eq(arch.get_chunks().size(), 3)
