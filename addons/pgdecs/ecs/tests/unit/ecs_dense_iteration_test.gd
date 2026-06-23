extends RefCounted
class_name ECSDenseIterationTest

const POSITION_ID: int = 1

func test_sparse_chunk_count_not_full_scan(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_INT32_ARRAY)
	ecs.create_entities(5, POSITION_ID)
	var query: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).build(ecs)
	var chunks: Array[ECSQueryChunk] = query.get_chunks()
	runner.assert_gt(chunks.size(), 0)
	var chunk: ECSQueryChunk = chunks[0]
	runner.assert_eq(chunk.get_entity_count(), 5)
	runner.assert_eq(chunk.get_size(), ECSEntityIdsUtils.CHUNK_SIZE)

func test_dense_entities_match_query_ids(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_INT32_ARRAY)
	var created: PackedInt64Array = ecs.create_entities(7, POSITION_ID)
	var query: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).build(ecs)
	var from_query: PackedInt64Array = query.get_entity_ids()
	runner.assert_eq(from_query.size(), created.size())
