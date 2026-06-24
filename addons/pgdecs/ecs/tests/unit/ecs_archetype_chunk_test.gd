extends RefCounted
class_name ECSArchetypeChunkTest

func test_dense_add_remove_count(runner: ECSTestRunner) -> void:
	var chunk: ECSArchetypeChunk = ECSArchetypeChunk.new()
	var handles: PackedInt64Array = PackedInt64Array()
	for i in range(10):
		var handle: int = ECSEntityHandle.make(i, 1)
		handles.append(handle)
		chunk.add_entity(handle)
	runner.assert_eq(chunk.get_entity_count(), 10)
	chunk.remove_entity(handles[3])
	runner.assert_eq(chunk.get_entity_count(), 9)
	runner.assert_false(chunk.has_entity(handles[3]))

func test_swap_remove_preserves_others(runner: ECSTestRunner) -> void:
	var chunk: ECSArchetypeChunk = ECSArchetypeChunk.new()
	var h1: int = ECSEntityHandle.make(1, 1)
	var h2: int = ECSEntityHandle.make(2, 1)
	var h3: int = ECSEntityHandle.make(3, 1)
	chunk.add_entity(h1)
	chunk.add_entity(h2)
	chunk.add_entity(h3)
	chunk.remove_entity(h2)
	runner.assert_true(chunk.has_entity(h1))
	runner.assert_true(chunk.has_entity(h3))
	runner.assert_eq(chunk.get_entity_count(), 2)

func test_slot_mapping(runner: ECSTestRunner) -> void:
	var chunk: ECSArchetypeChunk = ECSArchetypeChunk.new()
	var handle: int = ECSEntityHandle.make(42, 1)
	chunk.add_entity(handle)
	var slot: int = ECSEntityIdsUtils.slot_from_handle(handle)
	runner.assert_eq(chunk.get_slot_entity_id(slot), handle)

func test_slot_to_dense_mapping_updates_on_swap_remove(runner: ECSTestRunner) -> void:
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
	runner.assert_eq(chunk._slot_to_dense[slot_h1], -1)
	runner.assert_eq(chunk._slot_to_dense[slot_h3], 0)
	runner.assert_true(chunk.has_entity(h3))
	chunk.remove_entity(h3)
	runner.assert_false(chunk.has_entity(h3))
	runner.assert_eq(chunk.get_entity_count(), 1)

func test_structural_version_bumps_on_add(runner: ECSTestRunner) -> void:
	var chunk: ECSArchetypeChunk = ECSArchetypeChunk.new()
	var before: int = chunk.get_structural_version()
	var handle: int = ECSEntityHandle.make(1, 1)
	chunk.add_entity(handle)
	runner.assert_gt(chunk.get_structural_version(), before)

func test_structural_version_stable_on_duplicate_add(runner: ECSTestRunner) -> void:
	var chunk: ECSArchetypeChunk = ECSArchetypeChunk.new()
	var handle: int = ECSEntityHandle.make(1, 1)
	var before: int = chunk.get_structural_version()
	chunk.add_entity(handle)
	chunk.add_entity(handle)
	runner.assert_eq(chunk.get_structural_version(), before + 1)

func test_structural_version_bumps_on_remove(runner: ECSTestRunner) -> void:
	var chunk: ECSArchetypeChunk = ECSArchetypeChunk.new()
	var handle: int = ECSEntityHandle.make(1, 1)
	chunk.add_entity(handle)
	var after_add: int = chunk.get_structural_version()
	chunk.remove_entity(handle)
	runner.assert_gt(chunk.get_structural_version(), after_add)
	var after_remove: int = chunk.get_structural_version()
	chunk.remove_entity(handle)
	runner.assert_eq(chunk.get_structural_version(), after_remove)

func test_structural_version_bumps_on_clear(runner: ECSTestRunner) -> void:
	var chunk: ECSArchetypeChunk = ECSArchetypeChunk.new()
	chunk.add_entity(ECSEntityHandle.make(1, 1))
	var before: int = chunk.get_structural_version()
	chunk.clear()
	runner.assert_gt(chunk.get_structural_version(), before)

func test_dense_slots_consistent_after_adds(runner: ECSTestRunner) -> void:
	var chunk: ECSArchetypeChunk = ECSArchetypeChunk.new()
	var handles: PackedInt64Array = PackedInt64Array()
	for i in range(10):
		var handle: int = ECSEntityHandle.make(i, 1)
		handles.append(handle)
		chunk.add_entity(handle)
	var dense: PackedInt64Array = chunk.get_dense_entities()
	var dense_slots: PackedInt32Array = chunk.get_dense_slots()
	runner.assert_eq(chunk.get_entity_count(), 10)
	for i in range(chunk.get_entity_count()):
		var expected_slot: int = ECSEntityIdsUtils.slot_from_handle(dense[i])
		runner.assert_eq(dense_slots[i], expected_slot)

func test_dense_slots_updates_on_swap_remove(runner: ECSTestRunner) -> void:
	var chunk: ECSArchetypeChunk = ECSArchetypeChunk.new()
	var h1: int = ECSEntityHandle.make(1, 1)
	var h2: int = ECSEntityHandle.make(2, 1)
	var h3: int = ECSEntityHandle.make(3, 1)
	chunk.add_entity(h1)
	chunk.add_entity(h2)
	chunk.add_entity(h3)
	var slot_h3: int = ECSEntityIdsUtils.slot_from_handle(h3)
	chunk.remove_entity(h1)
	runner.assert_eq(chunk.get_dense_slots()[0], slot_h3)
	runner.assert_eq(chunk.get_dense_slots()[chunk.get_entity_count()], -1)
	runner.assert_true(chunk.has_entity(h3))

func test_dense_slots_cleared(runner: ECSTestRunner) -> void:
	var chunk: ECSArchetypeChunk = ECSArchetypeChunk.new()
	chunk.add_entity(ECSEntityHandle.make(1, 1))
	chunk.add_entity(ECSEntityHandle.make(2, 1))
	chunk.clear()
	for i in range(ECSEntityIdsUtils.CHUNK_SIZE):
		runner.assert_eq(chunk.get_dense_slots()[i], -1)
