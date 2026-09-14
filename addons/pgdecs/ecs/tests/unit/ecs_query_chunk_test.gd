extends GutTest
class_name ECSQueryChunkTest

const POSITION_ID: int = 1
const HEALTH_ID: int = 2
const MANA_ID: int = 3

func test_get_component_chunk_by_index() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	ecs.register_component(HEALTH_ID, ECSComponent.Type.PACKED_INT32)
	var entity_id: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID, HEALTH_ID]))
	var query: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).with_component(HEALTH_ID).build(ecs)
	var chunks: Array[ECSQueryChunk] = query.get_chunks()
	assert_gt(chunks.size(), 0)
	var chunk: ECSQueryChunk = chunks[0]
	var pos_chunk = chunk.get_component_chunk(POSITION_ID) as ECSComponentPackedVector2ArrayChunk
	var health_chunk = chunk.get_component_chunk(HEALTH_ID) as ECSComponentPackedInt32ArrayChunk
	assert_not_null(pos_chunk)
	assert_not_null(health_chunk)
	pos_chunk.set_component(entity_id, Vector2(7.0, 8.0))
	assert_eq(pos_chunk.get_component(entity_id), Vector2(7.0, 8.0))
	var slot: int = ECSEntityIdsUtils.slot_from_handle(entity_id)
	assert_eq(pos_chunk.get_value_at_slot(slot), Vector2(7.0, 8.0))

func test_empty_chunk_returns_null() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	var empty_chunk: ECSArchetypeChunk = ECSArchetypeChunk.new()
	var query_chunk: ECSQueryChunk = ECSQueryChunk.new(empty_chunk, ecs, 0)
	assert_eq(query_chunk.get_entity_count(), 0)
	assert_null(query_chunk.get_component_chunk(POSITION_ID))

func test_fast_path_matches_legacy_two_components() -> void:
	var ecs: ECSManager = _setup_pos_health_ecs()
	var pos: ECSComponentPackedVector2Array = ecs.get_component_array(POSITION_ID) as ECSComponentPackedVector2Array
	var health: ECSComponentPackedInt32Array = ecs.get_component_array(HEALTH_ID) as ECSComponentPackedInt32Array
	var ids: PackedInt64Array = ecs.create_entities_packed(5, PackedInt64Array([POSITION_ID, HEALTH_ID]))
	for i in ids.size():
		pos.set_component(ids[i], Vector2(float(i + 1), float(i + 2)))
		health.set_component(ids[i], (i + 1) * 10)
	var query: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).with_component(HEALTH_ID).build(ecs)
	for chunk in query.get_chunks():
		_assert_chunk_fast_matches_legacy(chunk, POSITION_ID, HEALTH_ID)

func test_fast_path_matches_legacy_after_removes_with_holes() -> void:
	var ecs: ECSManager = _setup_pos_health_ecs()
	var pos: ECSComponentPackedVector2Array = ecs.get_component_array(POSITION_ID) as ECSComponentPackedVector2Array
	var health: ECSComponentPackedInt32Array = ecs.get_component_array(HEALTH_ID) as ECSComponentPackedInt32Array
	var ids: PackedInt64Array = ecs.create_entities_packed(8, PackedInt64Array([POSITION_ID, HEALTH_ID]))
	for i in ids.size():
		pos.set_component(ids[i], Vector2(float(i), float(i * 2)))
		health.set_component(ids[i], i * 3)
	ecs.destroy_entity(ids[1])
	ecs.destroy_entity(ids[3])
	ecs.destroy_entity(ids[6])
	var query: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).with_component(HEALTH_ID).build(ecs)
	assert_eq(query.get_entity_ids().size(), 5)
	for chunk in query.get_chunks():
		_assert_chunk_fast_matches_legacy(chunk, POSITION_ID, HEALTH_ID)

func test_fast_path_excludes_other_archetype_on_shared_position_buffer() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	ecs.register_component(HEALTH_ID, ECSComponent.Type.PACKED_INT32)
	ecs.register_component(MANA_ID, ECSComponent.Type.PACKED_INT32)
	var pos: ECSComponentPackedVector2Array = ecs.get_component_array(POSITION_ID) as ECSComponentPackedVector2Array
	var health: ECSComponentPackedInt32Array = ecs.get_component_array(HEALTH_ID) as ECSComponentPackedInt32Array
	var mana: ECSComponentPackedInt32Array = ecs.get_component_array(MANA_ID) as ECSComponentPackedInt32Array
	var with_health: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID, HEALTH_ID]))
	var with_mana: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID, MANA_ID]))
	pos.set_component(with_health, Vector2(1.0, 2.0))
	health.set_component(with_health, 100)
	pos.set_component(with_mana, Vector2(999.0, 888.0))
	mana.set_component(with_mana, 777)
	var query: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).with_component(HEALTH_ID).build(ecs)
	assert_eq(query.get_entity_ids().size(), 1)
	var chunk: ECSQueryChunk = query.get_chunks()[0]
	var legacy: Dictionary = _collect_legacy_component_values(chunk, POSITION_ID, HEALTH_ID)
	var fast: Dictionary = _collect_fast_component_values(chunk, POSITION_ID, HEALTH_ID)
	assert_eq(legacy.size(), 1)
	assert_eq(fast.size(), 1)
	assert_eq(legacy[with_health]["pos"], Vector2(1.0, 2.0))
	assert_eq(legacy[with_health]["health"], 100)
	assert_eq(fast, legacy)

func test_fast_path_matches_legacy_three_components() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	ecs.register_component(HEALTH_ID, ECSComponent.Type.PACKED_INT32)
	ecs.register_component(MANA_ID, ECSComponent.Type.PACKED_INT32)
	var pos: ECSComponentPackedVector2Array = ecs.get_component_array(POSITION_ID) as ECSComponentPackedVector2Array
	var health: ECSComponentPackedInt32Array = ecs.get_component_array(HEALTH_ID) as ECSComponentPackedInt32Array
	var mana: ECSComponentPackedInt32Array = ecs.get_component_array(MANA_ID) as ECSComponentPackedInt32Array
	var ids: PackedInt64Array = ecs.create_entities_packed(4, PackedInt64Array([POSITION_ID, HEALTH_ID, MANA_ID]))
	for i in ids.size():
		pos.set_component(ids[i], Vector2(float(i), 1.0))
		health.set_component(ids[i], i + 1)
		mana.set_component(ids[i], (i + 1) * 100)
	ecs.destroy_entity(ids[2])
	var query: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).with_component(HEALTH_ID).with_component(MANA_ID).build(ecs)
	assert_eq(query.get_entity_ids().size(), 3)
	for chunk in query.get_chunks():
		_assert_chunk_fast_matches_legacy_three(chunk, POSITION_ID, HEALTH_ID, MANA_ID)

func _setup_pos_health_ecs() -> ECSManager:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	ecs.register_component(HEALTH_ID, ECSComponent.Type.PACKED_INT32)
	return ecs

func _assert_chunk_fast_matches_legacy(chunk: ECSQueryChunk, position_id: int, health_id: int) -> void:
	var legacy: Dictionary = _collect_legacy_component_values(chunk, position_id, health_id)
	var fast: Dictionary = _collect_fast_component_values(chunk, position_id, health_id)
	assert_eq(fast.size(), legacy.size())
	assert_eq(fast, legacy)

func _assert_chunk_fast_matches_legacy_three(
		chunk: ECSQueryChunk,
	position_id: int,
	health_id: int,
	mana_id: int
) -> void:
	var legacy: Dictionary = _collect_legacy_component_values_three(chunk, position_id, health_id, mana_id)
	var fast: Dictionary = _collect_fast_component_values_three(chunk, position_id, health_id, mana_id)
	assert_eq(fast.size(), legacy.size())
	assert_eq(fast, legacy)

func _collect_legacy_component_values(chunk: ECSQueryChunk, position_id: int, health_id: int) -> Dictionary:
	var result: Dictionary = {}
	var pos_chunk = chunk.get_component_chunk(position_id) as ECSComponentPackedVector2ArrayChunk
	var health_chunk = chunk.get_component_chunk(health_id) as ECSComponentPackedInt32ArrayChunk
	if pos_chunk == null or health_chunk == null:
		return result
	var count: int = chunk.get_entity_count()
	for i in range(count):
		var eid: int = chunk.get_entity_id_at(i)
		var slot: int = ECSEntityIdsUtils.slot_from_handle(eid)
		result[eid] = {
			"pos": pos_chunk.get_value_at_slot(slot),
			"health": health_chunk.get_value_at_slot(slot)
		}
	return result

func _collect_fast_component_values(chunk: ECSQueryChunk, position_id: int, health_id: int) -> Dictionary:
	var result: Dictionary = {}
	var pos_chunk = chunk.get_component_chunk(position_id) as ECSComponentPackedVector2ArrayChunk
	var health_chunk = chunk.get_component_chunk(health_id) as ECSComponentPackedInt32ArrayChunk
	if pos_chunk == null or health_chunk == null:
		return result
	var slots: PackedInt32Array = chunk.get_dense_slots()
	var count: int = chunk.get_entity_count()
	var pos_buf: PackedVector2Array = pos_chunk.get_values_buffer()
	var health_buf: PackedInt32Array = health_chunk.get_values_buffer()
	for i in range(count):
		var eid: int = chunk.get_entity_id_at(i)
		var slot: int = slots[i]
		result[eid] = {
			"pos": pos_buf[slot],
			"health": health_buf[slot]
		}
	return result

func _collect_legacy_component_values_three(
	chunk: ECSQueryChunk,
	position_id: int,
	health_id: int,
	mana_id: int
) -> Dictionary:
	var result: Dictionary = {}
	var pos_chunk = chunk.get_component_chunk(position_id) as ECSComponentPackedVector2ArrayChunk
	var health_chunk = chunk.get_component_chunk(health_id) as ECSComponentPackedInt32ArrayChunk
	var mana_chunk = chunk.get_component_chunk(mana_id) as ECSComponentPackedInt32ArrayChunk
	if pos_chunk == null or health_chunk == null or mana_chunk == null:
		return result
	var count: int = chunk.get_entity_count()
	for i in range(count):
		var eid: int = chunk.get_entity_id_at(i)
		var slot: int = ECSEntityIdsUtils.slot_from_handle(eid)
		result[eid] = {
			"pos": pos_chunk.get_value_at_slot(slot),
			"health": health_chunk.get_value_at_slot(slot),
			"mana": mana_chunk.get_value_at_slot(slot)
		}
	return result

func _collect_fast_component_values_three(
	chunk: ECSQueryChunk,
	position_id: int,
	health_id: int,
	mana_id: int
) -> Dictionary:
	var result: Dictionary = {}
	var pos_chunk = chunk.get_component_chunk(position_id) as ECSComponentPackedVector2ArrayChunk
	var health_chunk = chunk.get_component_chunk(health_id) as ECSComponentPackedInt32ArrayChunk
	var mana_chunk = chunk.get_component_chunk(mana_id) as ECSComponentPackedInt32ArrayChunk
	if pos_chunk == null or health_chunk == null or mana_chunk == null:
		return result
	var slots: PackedInt32Array = chunk.get_dense_slots()
	var count: int = chunk.get_entity_count()
	var pos_buf: PackedVector2Array = pos_chunk.get_values_buffer()
	var health_buf: PackedInt32Array = health_chunk.get_values_buffer()
	var mana_buf: PackedInt32Array = mana_chunk.get_values_buffer()
	for i in range(count):
		var eid: int = chunk.get_entity_id_at(i)
		var slot: int = slots[i]
		result[eid] = {
			"pos": pos_buf[slot],
			"health": health_buf[slot],
			"mana": mana_buf[slot]
		}
	return result
