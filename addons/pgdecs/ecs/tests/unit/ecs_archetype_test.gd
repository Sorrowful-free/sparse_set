extends GutTest
class_name ECSArchetypeTest

func test_add_has_remove_entity() -> void:
	var bits: PackedInt64Array = PackedInt64Array([1])
	var component_ids: PackedInt64Array = PackedInt64Array([1])
	var arch: ECSArchetype = ECSArchetype.new(bits, component_ids)
	var entity: int = ECSEntityHandle.make(100, 1)
	assert_false(arch.has_entity(entity))
	arch.add_entity(entity)
	assert_true(arch.has_entity(entity))
	var chunk: ECSArchetypeChunk = arch.get_archetype_chunk(100)
	assert_eq(chunk.get_entity_count(), 1)
	arch.remove_entity(entity)
	assert_false(arch.has_entity(entity))
	assert_eq(chunk.get_entity_count(), 0)

func test_multiple_chunks() -> void:
	var bits: PackedInt64Array = PackedInt64Array([1])
	var component_ids: PackedInt64Array = PackedInt64Array([1])
	var arch: ECSArchetype = ECSArchetype.new(bits, component_ids)
	arch.add_entity(ECSEntityHandle.make(0, 1))
	arch.add_entity(ECSEntityHandle.make(256, 1))
	arch.add_entity(ECSEntityHandle.make(512, 1))
	assert_true(arch.has_entity(ECSEntityHandle.make(0, 1)))
	assert_true(arch.has_entity(ECSEntityHandle.make(256, 1)))
	assert_true(arch.has_entity(ECSEntityHandle.make(512, 1)))
	assert_eq(arch.get_chunk_indices().size(), 3)

func test_dense_swap_remove() -> void:
	var bits: PackedInt64Array = PackedInt64Array([1])
	var arch: ECSArchetype = ECSArchetype.new(bits, PackedInt64Array([1]))
	var e1: int = ECSEntityHandle.make(10, 1)
	var e2: int = ECSEntityHandle.make(11, 1)
	var e3: int = ECSEntityHandle.make(12, 1)
	arch.add_entity(e1)
	arch.add_entity(e2)
	arch.add_entity(e3)
	var chunk: ECSArchetypeChunk = arch.get_archetype_chunk(10)
	assert_eq(chunk.get_entity_count(), 3)
	arch.remove_entity(e2)
	assert_eq(chunk.get_entity_count(), 2)
	assert_false(chunk.has_entity(e2))
	assert_true(chunk.has_entity(e1))
	assert_true(chunk.has_entity(e3))

func test_remove_entities_batch() -> void:
	var bits: PackedInt64Array = PackedInt64Array([1])
	var arch: ECSArchetype = ECSArchetype.new(bits, PackedInt64Array([1]))
	var handles: PackedInt64Array = PackedInt64Array()
	for i in range(10):
		var h: int = ECSEntityHandle.make(100 + i, 1)
		arch.add_entity(h)
		handles.append(h)
	var chunk: ECSArchetypeChunk = arch.get_archetype_chunk(100)
	assert_eq(chunk.get_entity_count(), 10)
	arch.remove_entities_batch(handles)
	assert_eq(chunk.get_entity_count(), 0)

func test_remove_entities_batch_multi_chunk() -> void:
	var bits: PackedInt64Array = PackedInt64Array([1])
	var arch: ECSArchetype = ECSArchetype.new(bits, PackedInt64Array([1]))
	var low: int = ECSEntityHandle.make(10, 1)
	var high: int = ECSEntityHandle.make(5000, 1)
	arch.add_entity(low)
	arch.add_entity(high)
	assert_eq(arch.get_live_count(), 2)
	assert_eq(arch.get_chunk_indices().size(), 2)
	arch.remove_entities_batch(PackedInt64Array([low, high]))
	assert_eq(arch.get_live_count(), 0)
	assert_eq(arch.get_chunk_indices().size(), 0)

func test_high_entity_index_allocates_single_chunk() -> void:
	var bits: PackedInt64Array = PackedInt64Array([1])
	var arch: ECSArchetype = ECSArchetype.new(bits, PackedInt64Array([1]))
	arch.add_entity(ECSEntityHandle.make(5000, 1))
	assert_eq(arch.get_chunk_indices().size(), 1)
	assert_eq(arch.get_chunk_indices()[0], ECSEntityIdsUtils.get_chunk_index(5000))
	assert_true(arch.has_entity(ECSEntityHandle.make(5000, 1)))
