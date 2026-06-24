extends GutTest
class_name ECSArchetypeChunkTest

func test_dense_add_remove_count() -> void:
	var chunk: ECSArchetypeChunk = ECSArchetypeChunk.new()
	var handles: PackedInt64Array = PackedInt64Array()
	for i in range(10):
		var handle: int = ECSEntityHandle.make(i, 1)
		handles.append(handle)
		chunk.add_entity(handle)
	assert_eq(chunk.get_entity_count(), 10)
	chunk.remove_entity(handles[3])
	assert_eq(chunk.get_entity_count(), 9)
	assert_false(chunk.has_entity(handles[3]))

func test_swap_remove_preserves_others() -> void:
	var chunk: ECSArchetypeChunk = ECSArchetypeChunk.new()
	var h1: int = ECSEntityHandle.make(1, 1)
	var h2: int = ECSEntityHandle.make(2, 1)
	var h3: int = ECSEntityHandle.make(3, 1)
	chunk.add_entity(h1)
	chunk.add_entity(h2)
	chunk.add_entity(h3)
	chunk.remove_entity(h2)
	assert_true(chunk.has_entity(h1))
	assert_true(chunk.has_entity(h3))
	assert_eq(chunk.get_entity_count(), 2)

func test_slot_mapping() -> void:
	var chunk: ECSArchetypeChunk = ECSArchetypeChunk.new()
	var handle: int = ECSEntityHandle.make(42, 1)
	chunk.add_entity(handle)
	var slot: int = ECSEntityIdsUtils.slot_from_handle(handle)
	assert_eq(chunk.get_slot_entity_id(slot), handle)

func test_slot_to_dense_mapping_updates_on_swap_remove() -> void:
	var chunk: ECSArchetypeChunk = ECSArchetypeChunk.new()
	var h1: int = ECSEntityHandle.make(1, 1)
	var h2: int = ECSEntityHandle.make(2, 1)
	var h3: int = ECSEntityHandle.make(3, 1)
	chunk.add_entity(h1)
	chunk.add_entity(h2)
	chunk.add_entity(h3)
	var slot_h1: int = ECSEntityIdsUtils.slot_from_handle(h1)
	var slot_h3: int = ECSEntityIdsUtils.slot_from_handle(h3)
	chunk.remove_entity(h1)
	assert_eq(chunk._slot_to_dense[slot_h1], -1)
	assert_eq(chunk._slot_to_dense[slot_h3], 0)
	assert_true(chunk.has_entity(h3))
	chunk.remove_entity(h3)
	assert_false(chunk.has_entity(h3))
	assert_eq(chunk.get_entity_count(), 1)

func test_structural_version_bumps_on_add() -> void:
	var chunk: ECSArchetypeChunk = ECSArchetypeChunk.new()
	var before: int = chunk.get_structural_version()
	var handle: int = ECSEntityHandle.make(1, 1)
	chunk.add_entity(handle)
	assert_gt(chunk.get_structural_version(), before)

func test_structural_version_stable_on_duplicate_add() -> void:
	var chunk: ECSArchetypeChunk = ECSArchetypeChunk.new()
	var handle: int = ECSEntityHandle.make(1, 1)
	var before: int = chunk.get_structural_version()
	chunk.add_entity(handle)
	chunk.add_entity(handle)
	assert_eq(chunk.get_structural_version(), before + 1)

func test_structural_version_bumps_on_remove() -> void:
	var chunk: ECSArchetypeChunk = ECSArchetypeChunk.new()
	var handle: int = ECSEntityHandle.make(1, 1)
	chunk.add_entity(handle)
	var after_add: int = chunk.get_structural_version()
	chunk.remove_entity(handle)
	assert_gt(chunk.get_structural_version(), after_add)
	var after_remove: int = chunk.get_structural_version()
	chunk.remove_entity(handle)
	assert_eq(chunk.get_structural_version(), after_remove)

func test_structural_version_bumps_on_clear() -> void:
	var chunk: ECSArchetypeChunk = ECSArchetypeChunk.new()
	chunk.add_entity(ECSEntityHandle.make(1, 1))
	var before: int = chunk.get_structural_version()
	chunk.clear()
	assert_gt(chunk.get_structural_version(), before)

func test_dense_slots_consistent_after_adds() -> void:
	var chunk: ECSArchetypeChunk = ECSArchetypeChunk.new()
	var handles: PackedInt64Array = PackedInt64Array()
	for i in range(10):
		var handle: int = ECSEntityHandle.make(i, 1)
		handles.append(handle)
		chunk.add_entity(handle)
	var dense: PackedInt64Array = chunk.get_dense_entities()
	var dense_slots: PackedInt32Array = chunk.get_dense_slots()
	assert_eq(chunk.get_entity_count(), 10)
	for i in range(chunk.get_entity_count()):
		var expected_slot: int = ECSEntityIdsUtils.slot_from_handle(dense[i])
		assert_eq(dense_slots[i], expected_slot)

func test_dense_slots_updates_on_swap_remove() -> void:
	var chunk: ECSArchetypeChunk = ECSArchetypeChunk.new()
	var h1: int = ECSEntityHandle.make(1, 1)
	var h2: int = ECSEntityHandle.make(2, 1)
	var h3: int = ECSEntityHandle.make(3, 1)
	chunk.add_entity(h1)
	chunk.add_entity(h2)
	chunk.add_entity(h3)
	var slot_h3: int = ECSEntityIdsUtils.slot_from_handle(h3)
	chunk.remove_entity(h1)
	assert_eq(chunk.get_dense_slots()[0], slot_h3)
	assert_eq(chunk.get_dense_slots()[chunk.get_entity_count()], -1)
	assert_true(chunk.has_entity(h3))

func test_dense_slots_cleared() -> void:
	var chunk: ECSArchetypeChunk = ECSArchetypeChunk.new()
	chunk.add_entity(ECSEntityHandle.make(1, 1))
	chunk.add_entity(ECSEntityHandle.make(2, 1))
	chunk.clear()
	for i in range(ECSEntityIdsUtils.CHUNK_SIZE):
		assert_eq(chunk.get_dense_slots()[i], -1)
