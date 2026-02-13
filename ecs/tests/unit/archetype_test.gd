extends RefCounted
class_name ArchetypeTest

func test_add_has_remove_entity(runner: ECSTestRunner) -> void:
	var bits: PackedInt64Array = PackedInt64Array([1])
	var component_ids: PackedInt64Array = PackedInt64Array([1])
	var arch: Archetype = Archetype.new(bits, component_ids)
	runner.assert_false(arch.has_entity(100))
	arch.add_entity(100)
	runner.assert_true(arch.has_entity(100))
	arch.remove_entity(100)
	runner.assert_false(arch.has_entity(100))

func test_multiple_chunks(runner: ECSTestRunner) -> void:
	var bits: PackedInt64Array = PackedInt64Array([1])
	var component_ids: PackedInt64Array = PackedInt64Array([1])
	var arch: Archetype = Archetype.new(bits, component_ids)
	arch.add_entity(0)
	arch.add_entity(256)
	arch.add_entity(512)
	runner.assert_true(arch.has_entity(0))
	runner.assert_true(arch.has_entity(256))
	runner.assert_true(arch.has_entity(512))
	runner.assert_eq(arch.get_chunks().size(), 3)
