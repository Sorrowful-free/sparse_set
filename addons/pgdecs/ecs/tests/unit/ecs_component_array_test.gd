extends GutTest
class_name ECSComponentArrayTest

const POSITION_ID: int = 1

func test_add_get_set_remove() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	var pos: ECSComponentVector2Array = ecs.get_component_array(POSITION_ID) as ECSComponentVector2Array
	var entity_id: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	pos.set_component(entity_id, Vector2(3.0, 4.0))
	assert_eq(pos.get_component(entity_id), Vector2(3.0, 4.0))
	ecs.remove_component(entity_id, POSITION_ID)
	assert_false(ecs.has_component(entity_id, POSITION_ID))

func test_batch_add_remove() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_FLOAT32_ARRAY)
	var health_id: int = 2
	ecs.register_component(health_id, TYPE_PACKED_FLOAT32_ARRAY)
	var ids: PackedInt64Array = ecs.create_entities_packed(4, PackedInt64Array([POSITION_ID, health_id]))
	for entity_id in ids:
		assert_true(ecs.has_component(entity_id, health_id))
	ecs.destroy_entities_packed(ids)
	for entity_id in ids:
		assert_false(ecs.is_alive(entity_id))

func test_chunk_boundary() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_INT32_ARRAY)
	var ids: PackedInt64Array = ecs.create_entities_packed(300, PackedInt64Array([POSITION_ID]))
	var comp: ECSComponentInt32Array = ecs.get_component_array(POSITION_ID) as ECSComponentInt32Array
	assert_gt(comp.size_chunks(), 1)
	for entity_id in ids:
		comp.set_component(entity_id, 42)
		assert_eq(comp.get_component(entity_id), 42)

func test_slot_api() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	var entity_id: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	var chunk: ECSComponentVector2ArrayChunk = ecs.get_component_array(POSITION_ID).get_chunk(entity_id) as ECSComponentVector2ArrayChunk
	assert_not_null(chunk)
	var slot: int = ECSEntityIdsUtils.slot_from_handle(entity_id)
	chunk.set_value_at_slot(slot, Vector2(5.0, 6.0))
	assert_eq(chunk.get_value_at_slot(slot), Vector2(5.0, 6.0))

func test_value_version_bumps_on_set_value_at_slot() -> void:
	var chunk: ECSComponentVector2ArrayChunk = ECSComponentVector2ArrayChunk.new()
	var before: int = chunk.get_value_version()
	chunk.set_value_at_slot(0, Vector2(1.0, 2.0))
	assert_gt(chunk.get_value_version(), before)

func test_value_version_bumps_on_add_component() -> void:
	var chunk: ECSComponentVector2ArrayChunk = ECSComponentVector2ArrayChunk.new()
	var handle: int = ECSEntityHandle.make(1, 1)
	var before: int = chunk.get_value_version()
	chunk.add_component(handle, Vector2(1.0, 2.0))
	assert_gt(chunk.get_value_version(), before)

func test_value_version_bumps_on_remove_component() -> void:
	var chunk: ECSComponentVector2ArrayChunk = ECSComponentVector2ArrayChunk.new()
	var handle: int = ECSEntityHandle.make(1, 1)
	chunk.add_component(handle, Vector2(1.0, 2.0))
	var before: int = chunk.get_value_version()
	chunk.remove_component(ECSEntityIdsUtils.slot_from_handle(handle))
	assert_gt(chunk.get_value_version(), before)

func test_value_version_bumps_on_clear() -> void:
	var chunk: ECSComponentVector2ArrayChunk = ECSComponentVector2ArrayChunk.new()
	chunk.add_component(ECSEntityHandle.make(1, 1), Vector2(1.0, 2.0))
	var before: int = chunk.get_value_version()
	chunk.clear()
	assert_gt(chunk.get_value_version(), before)

func test_sparse_chunk_map_high_index() -> void:
	var comp: ECSComponentInt32Array = ECSComponentInt32Array.new()
	var entity_id: int = ECSEntityHandle.make(5000, 1)
	comp.add_entity(entity_id)
	assert_eq(comp.size_chunks(), 1)
	var expected_chunk_index: int = ECSEntityIdsUtils.get_chunk_index(5000)
	assert_eq(comp.get_chunk_indices().size(), 1)
	assert_eq(comp.get_chunk_indices()[0], expected_chunk_index)
	assert_not_null(comp.get_chunk_by_index(expected_chunk_index))
	comp.evict_chunk_by_index(expected_chunk_index)
	assert_eq(comp.size_chunks(), 0)
	assert_eq(comp.get_chunk_indices().size(), 0)

func test_sparse_evict_swaps_dense() -> void:
	var comp: ECSComponentInt32Array = ECSComponentInt32Array.new()
	comp.add_entity(ECSEntityHandle.make(0, 1))
	comp.add_entity(ECSEntityHandle.make(512, 1))
	assert_eq(comp.size_chunks(), 2)
	comp.evict_chunk_by_index(0)
	assert_eq(comp.size_chunks(), 1)
	assert_eq(comp.get_chunk_indices().size(), 1)
	assert_eq(comp.get_chunk_indices()[0], ECSEntityIdsUtils.get_chunk_index(512))
	assert_null(comp.get_chunk_by_index(0))
