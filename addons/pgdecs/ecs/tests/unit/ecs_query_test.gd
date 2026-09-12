extends GutTest
class_name ECSQueryTest

const POSITION_ID: int = 1
const HEALTH_ID: int = 2
const TAG_ID: int = 3

func test_query_match_all() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	ecs.register_component(HEALTH_ID, ECSComponent.Type.PACKED_INT32)
	var with_pos: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	var with_both: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID, HEALTH_ID]))
	var query: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).with_component(HEALTH_ID).build(ecs)
	assert_false(query.match(with_pos))
	assert_true(query.match(with_both))

func test_query_without() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	ecs.register_component(TAG_ID, ECSComponent.Type.PACKED_INT32)
	var only_pos: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	var pos_and_tag: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID, TAG_ID]))
	var q: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).without_component(TAG_ID).build(ecs)
	assert_true(q.match(only_pos))
	assert_false(q.match(pos_and_tag))

func test_get_entity_ids() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	ecs.register_component(HEALTH_ID, ECSComponent.Type.PACKED_INT32)
	var tmp = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	var e2: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID, HEALTH_ID]))
	var e3: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID, HEALTH_ID]))
	var query: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).with_component(HEALTH_ID).build(ecs)
	var ids: PackedInt64Array = query.get_entity_ids()
	assert_eq(ids.size(), 2)
	assert_true(ids.find(e2) >= 0)
	assert_true(ids.find(e3) >= 0)

## get_chunks() возвращает те же сущности, что и get_entity_ids(); итерация по чанкам даёт тот же набор.
func test_get_chunks_same_entities_as_get_entity_ids() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	ecs.register_component(HEALTH_ID, ECSComponent.Type.PACKED_INT32)
	ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	var e2: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID, HEALTH_ID]))
	var e3: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID, HEALTH_ID]))
	var query: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).with_component(HEALTH_ID).build(ecs)
	var from_ids: PackedInt64Array = query.get_entity_ids()
	var from_chunks: PackedInt64Array = PackedInt64Array()
	for chunk in query.get_chunks():
		var dense: PackedInt64Array = chunk.get_dense_entities()
		var count: int = chunk.get_entity_count()
		for i in range(count):
			from_chunks.append(dense[i])
	assert_eq(from_chunks.size(), from_ids.size())
	assert_true(from_chunks.find(e2) >= 0)
	assert_true(from_chunks.find(e3) >= 0)

## Итерация строго по чанкам: get_entity_count() и get_entity_id_at() согласованы.
func test_get_chunks_iterate_by_chunk() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	ecs.register_component(HEALTH_ID, ECSComponent.Type.PACKED_INT32)
	var created: PackedInt64Array = ecs.create_entities_packed(5, PackedInt64Array([POSITION_ID, HEALTH_ID]))
	var query: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).with_component(HEALTH_ID).build(ecs)
	var chunks: Array[ECSQueryChunk] = query.get_chunks()
	assert_gt(chunks.size(), 0)
	var total: int = 0
	for chunk in chunks:
		var qc: ECSQueryChunk = chunk as ECSQueryChunk
		assert_not_null(qc)
		var count: int = qc.get_entity_count()
		for i in range(count):
			assert_true(qc.get_entity_id_at(i) >= 0)
		total += count
	assert_eq(total, created.size())

func test_for_each_chunk_matches_get_chunks() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	ecs.register_component(HEALTH_ID, ECSComponent.Type.PACKED_INT32)
	ecs.create_entities_packed(5, PackedInt64Array([POSITION_ID, HEALTH_ID]))
	var query: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).with_component(HEALTH_ID).build(ecs)
	var from_foreach: PackedInt64Array = PackedInt64Array()
	query.for_each_chunk(func(chunk: ECSQueryChunk) -> void:
		var dense: PackedInt64Array = chunk.get_dense_entities()
		var count: int = chunk.get_entity_count()
		for i in range(count):
			from_foreach.append(dense[i])
	)
	var from_chunks: PackedInt64Array = PackedInt64Array()
	for chunk in query.get_chunks():
		var dense: PackedInt64Array = chunk.get_dense_entities()
		var count: int = chunk.get_entity_count()
		for i in range(count):
			from_chunks.append(dense[i])
	assert_eq(from_foreach.size(), from_chunks.size())
	for entity_id in from_foreach:
		assert_true(from_chunks.find(entity_id) >= 0)

func test_collect_chunks_matches_get_chunks() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	ecs.register_component(HEALTH_ID, ECSComponent.Type.PACKED_INT32)
	ecs.create_entities_packed(5, PackedInt64Array([POSITION_ID, HEALTH_ID]))
	var query: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).with_component(HEALTH_ID).build(ecs)
	var collected: Array[ECSQueryChunk] = []
	query.collect_chunks(collected)
	var from_get: Array[ECSQueryChunk] = query.get_chunks()
	assert_eq(collected.size(), from_get.size())
	for i in range(collected.size()):
		assert_eq(collected[i].get_entity_count(), from_get[i].get_entity_count())

func test_get_chunks_snapshots_do_not_alias() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	ecs.register_component(HEALTH_ID, ECSComponent.Type.PACKED_INT32)
	ecs.create_entities_packed(3, PackedInt64Array([POSITION_ID, HEALTH_ID]))
	var query: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).with_component(HEALTH_ID).build(ecs)
	var independent: Array[ECSQueryChunk] = []
	query.collect_chunks(independent, false)
	var pooled: Array[ECSQueryChunk] = []
	query.collect_chunks(pooled, true)
	assert_gt(independent.size(), 0)
	assert_eq(independent.size(), pooled.size())
	for i in range(independent.size()):
		assert_false(independent[i] == pooled[i])
		assert_eq(independent[i].get_entity_count(), pooled[i].get_entity_count())
	query.begin_chunk_run()
	for i in range(pooled.size()):
		assert_eq(pooled[i].get_entity_count(), independent[i].get_entity_count())

func test_begin_chunk_run_matches_for_each_chunk() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	ecs.register_component(HEALTH_ID, ECSComponent.Type.PACKED_INT32)
	ecs.create_entities_packed(12, PackedInt64Array([POSITION_ID, HEALTH_ID]))
	var query: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).with_component(HEALTH_ID).build(ecs)
	var from_foreach: PackedInt64Array = PackedInt64Array()
	query.for_each_chunk(func(chunk: ECSQueryChunk) -> void:
		var dense: PackedInt64Array = chunk.get_dense_entities()
		for i in range(chunk.get_entity_count()):
			from_foreach.append(dense[i])
	)
	var from_run: PackedInt64Array = PackedInt64Array()
	var run_count: int = query.begin_chunk_run()
	for i in range(run_count):
		var chunk: ECSQueryChunk = query.get_chunk_at_run_index(i)
		var dense: PackedInt64Array = chunk.get_dense_entities()
		for j in range(chunk.get_entity_count()):
			from_run.append(dense[j])
	assert_eq(from_run.size(), from_foreach.size())
	for entity_id in from_foreach:
		assert_true(from_run.find(entity_id) >= 0)

func test_collect_chunks_reuses_pool_after_warmup() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	ecs.register_component(HEALTH_ID, ECSComponent.Type.PACKED_INT32)
	ecs.create_entities_packed(300, PackedInt64Array([POSITION_ID, HEALTH_ID]))
	var query: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).with_component(HEALTH_ID).build(ecs)
	var warmup: Array[ECSQueryChunk] = []
	query.collect_chunks(warmup)
	var pool_after_warmup: int = query.get_chunk_pool_size()
	assert_gt(pool_after_warmup, 0)
	query.collect_chunks(warmup)
	assert_eq(query.get_chunk_pool_size(), pool_after_warmup)

func test_get_component_ids_returns_query_components() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	ecs.register_component(HEALTH_ID, ECSComponent.Type.PACKED_INT32)
	ecs.create_entities_packed(1, PackedInt64Array([POSITION_ID, HEALTH_ID]))
	var query: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).with_component(HEALTH_ID).build(ecs)
	assert_eq(query.get_component_ids(), PackedInt64Array([POSITION_ID, HEALTH_ID]))

func test_query_chunk_exposes_versions() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	ecs.register_component(HEALTH_ID, ECSComponent.Type.PACKED_INT32)
	var ids: PackedInt64Array = ecs.create_entities_packed(2, PackedInt64Array([POSITION_ID, HEALTH_ID]))
	var query: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).with_component(HEALTH_ID).build(ecs)
	var snap: Dictionary = {"struct": -1, "value": -1}
	query.for_each_chunk(func(chunk: ECSQueryChunk) -> void:
		snap["struct"] = chunk.get_structural_version()
		snap["value"] = chunk.get_component_version(POSITION_ID)
	)
	assert_gt(snap["struct"], -1)
	assert_gt(snap["value"], -1)
	var pos: ECSComponentVector2Array = ecs.get_component_array(POSITION_ID) as ECSComponentVector2Array
	pos.set_component(ids[0], Vector2(9.0, 9.0))
	var snap2: Dictionary = {"value": -1}
	query.for_each_chunk(func(chunk: ECSQueryChunk) -> void:
		snap2["value"] = chunk.get_component_version(POSITION_ID)
	)
	assert_gt(snap2["value"], snap["value"])
	ecs.create_entities_packed(1, PackedInt64Array([POSITION_ID, HEALTH_ID]))
	var snap3: Dictionary = {"struct": -1}
	query.for_each_chunk(func(chunk: ECSQueryChunk) -> void:
		snap3["struct"] = chunk.get_structural_version()
	)
	assert_gt(snap3["struct"], snap["struct"])

func test_query_builder_deduplicates_and_sorts_component_ids() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	ecs.register_component(HEALTH_ID, ECSComponent.Type.PACKED_INT32)
	ecs.register_component(TAG_ID, ECSComponent.Type.PACKED_INT32)
	var matched: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID, HEALTH_ID]))
	var filtered: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID, HEALTH_ID, TAG_ID]))
	var query: ECSQuery = ECSQueryBuilder.new() \
		.with_component(HEALTH_ID) \
		.with_component(POSITION_ID) \
		.with_component(POSITION_ID) \
		.without_component(TAG_ID) \
		.without_component(POSITION_ID) \
		.without_component(TAG_ID) \
		.build(ecs)
	assert_eq(query._component_ids, PackedInt64Array([POSITION_ID, HEALTH_ID]))
	assert_eq(query._without_component_ids, PackedInt64Array([TAG_ID]))
	assert_true(query.match(matched))
	assert_false(query.match(filtered))

func test_query_builder_with_components_batch() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	ecs.register_component(HEALTH_ID, ECSComponent.Type.PACKED_INT32)
	ecs.register_component(TAG_ID, ECSComponent.Type.PACKED_INT32)
	var matched: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID, HEALTH_ID]))
	var filtered: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID, HEALTH_ID, TAG_ID]))
	var query: ECSQuery = ECSQueryBuilder.new() \
		.with_components([HEALTH_ID, POSITION_ID, POSITION_ID]) \
		.without_components([TAG_ID, POSITION_ID, TAG_ID]) \
		.build(ecs)
	assert_eq(query._component_ids, PackedInt64Array([POSITION_ID, HEALTH_ID]))
	assert_eq(query._without_component_ids, PackedInt64Array([TAG_ID]))
	assert_true(query.match(matched))
	assert_false(query.match(filtered))
