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
	var chunk: ECSArchetypeChunk = arch.get_archetype_chunk(100)
	runner.assert_eq(chunk.get_entity_count(), 1)
	arch.remove_entity(entity)
	runner.assert_false(arch.has_entity(entity))
	runner.assert_eq(chunk.get_entity_count(), 0)

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
	runner.assert_eq(arch.get_chunk_indices().size(), 3)

func test_dense_swap_remove(runner: ECSTestRunner) -> void:
	var bits: PackedInt64Array = PackedInt64Array([1])
	var arch: ECSArchetype = ECSArchetype.new(bits, PackedInt64Array([1]))
	var e1: int = ECSEntityHandle.make(10, 1)
	var e2: int = ECSEntityHandle.make(11, 1)
	var e3: int = ECSEntityHandle.make(12, 1)
	arch.add_entity(e1)
	arch.add_entity(e2)
	arch.add_entity(e3)
	var chunk: ECSArchetypeChunk = arch.get_archetype_chunk(10)
	runner.assert_eq(chunk.get_entity_count(), 3)
	arch.remove_entity(e2)
	runner.assert_eq(chunk.get_entity_count(), 2)
	runner.assert_false(chunk.has_entity(e2))
	runner.assert_true(chunk.has_entity(e1))
	runner.assert_true(chunk.has_entity(e3))

func test_remove_entities_batch(runner: ECSTestRunner) -> void:
	var bits: PackedInt64Array = PackedInt64Array([1])
	var arch: ECSArchetype = ECSArchetype.new(bits, PackedInt64Array([1]))
	var handles: PackedInt64Array = PackedInt64Array()
	for i in range(10):
		var h: int = ECSEntityHandle.make(100 + i, 1)
		arch.add_entity(h)
		handles.append(h)
	var chunk: ECSArchetypeChunk = arch.get_archetype_chunk(100)
	runner.assert_eq(chunk.get_entity_count(), 10)
	arch.remove_entities_batch(handles)
	runner.assert_eq(chunk.get_entity_count(), 0)

func test_remove_entities_batch_multi_chunk(runner: ECSTestRunner) -> void:
	var bits: PackedInt64Array = PackedInt64Array([1])
	var arch: ECSArchetype = ECSArchetype.new(bits, PackedInt64Array([1]))
	var low: int = ECSEntityHandle.make(10, 1)
	var high: int = ECSEntityHandle.make(5000, 1)
	arch.add_entity(low)
	arch.add_entity(high)
	runner.assert_eq(arch.get_live_count(), 2)
	runner.assert_eq(arch.get_chunk_indices().size(), 2)
	arch.remove_entities_batch(PackedInt64Array([low, high]))
	runner.assert_eq(arch.get_live_count(), 0)
	runner.assert_eq(arch.get_chunk_indices().size(), 0)

func test_high_entity_index_allocates_single_chunk(runner: ECSTestRunner) -> void:
	var bits: PackedInt64Array = PackedInt64Array([1])
	var arch: ECSArchetype = ECSArchetype.new(bits, PackedInt64Array([1]))
	arch.add_entity(ECSEntityHandle.make(5000, 1))
	runner.assert_eq(arch.get_chunk_indices().size(), 1)
	runner.assert_eq(arch.get_chunk_indices()[0], ECSEntityIdsUtils.get_chunk_index(5000))
	runner.assert_true(arch.has_entity(ECSEntityHandle.make(5000, 1)))
