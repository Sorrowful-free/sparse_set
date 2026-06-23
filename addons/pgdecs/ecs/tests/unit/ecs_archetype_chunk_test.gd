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
