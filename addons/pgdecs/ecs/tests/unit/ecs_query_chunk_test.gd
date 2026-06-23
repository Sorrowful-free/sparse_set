extends RefCounted
class_name ECSQueryChunkTest

const POSITION_ID: int = 1
const HEALTH_ID: int = 2

func test_get_component_chunk_by_index(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	ecs.register_component(HEALTH_ID, TYPE_PACKED_INT32_ARRAY)
	var entity_id: int = ecs.create_entity(POSITION_ID, HEALTH_ID)
	var query: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).with_component(HEALTH_ID).build(ecs)
	var chunks: Array[ECSQueryChunk] = query.get_chunks()
	runner.assert_gt(chunks.size(), 0)
	var chunk: ECSQueryChunk = chunks[0]
	var pos_chunk = chunk.get_component_chunk(POSITION_ID) as ECSComponentVector2ArrayChunk
	var health_chunk = chunk.get_component_chunk(HEALTH_ID) as ECSComponentInt32ArrayChunk
	runner.assert_not_null(pos_chunk)
	runner.assert_not_null(health_chunk)
	pos_chunk.set_component(entity_id, Vector2(7.0, 8.0))
	runner.assert_eq(pos_chunk.get_component(entity_id), Vector2(7.0, 8.0))

func test_empty_chunk_returns_null(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	var empty_chunk: PackedInt64Array = PackedInt64Array()
	empty_chunk.resize(ECSEntityIdsUtils.CHUNK_SIZE)
	empty_chunk.fill(-1)
	var query_chunk: ECSQueryChunk = ECSQueryChunk.new(empty_chunk, ecs, 0)
	runner.assert_null(query_chunk.get_component_chunk(POSITION_ID))
