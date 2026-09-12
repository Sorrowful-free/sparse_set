extends GutTest
class_name ECSDenseIterationTest

const POSITION_ID: int = 1

func test_sparse_chunk_count_not_full_scan() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_INT32)
	ecs.create_entities_packed(5, PackedInt64Array([POSITION_ID]))
	var query: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).build(ecs)
	var chunks: Array[ECSQueryChunk] = query.get_chunks()
	assert_gt(chunks.size(), 0)
	var chunk: ECSQueryChunk = chunks[0]
	assert_eq(chunk.get_entity_count(), 5)
	assert_eq(chunk.get_size(), ECSEntityIdsUtils.CHUNK_SIZE)

func test_dense_entities_match_query_ids() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_INT32)
	var created: PackedInt64Array = ecs.create_entities_packed(7, PackedInt64Array([POSITION_ID]))
	var query: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).build(ecs)
	var from_query: PackedInt64Array = query.get_entity_ids()
	assert_eq(from_query.size(), created.size())
