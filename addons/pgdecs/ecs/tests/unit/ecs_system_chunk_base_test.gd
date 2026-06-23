extends RefCounted
class_name ECSSystemChunkBaseTest

const VALUE_ID: int = 1

class _SumChunkSystem extends ECSSystemChunkBase:
	var processed_chunks: int = 0
	var processed_entities: int = 0

	func _build_query() -> ECSQuery:
		return ECSQueryBuilder.new().with_component(VALUE_ID).build(get_ecs_manager())

	func process_chunk(chunk: ECSQueryChunk, _delta: float) -> void:
		processed_chunks += 1
		var comp_chunk = chunk.get_component_chunk(VALUE_ID) as ECSComponentFloat32ArrayChunk
		if comp_chunk == null:
			return
		var count: int = chunk.get_entity_count()
		var dense: PackedInt64Array = chunk.get_dense_entities()
		for i in range(count):
			var handle: int = dense[i]
			var slot: int = ECSEntityIdsUtils.slot_from_handle(handle)
			processed_entities += 1
			comp_chunk.get_value_at_slot(slot)

func test_process_chunk_single_thread(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(VALUE_ID, TYPE_PACKED_FLOAT32_ARRAY)
	ecs.create_entities(3, VALUE_ID)
	var system: _SumChunkSystem = _SumChunkSystem.new(ecs)
	system.update(0.016)
	runner.assert_gt(system.processed_chunks, 0)
	runner.assert_eq(system.processed_entities, 3)

func test_process_chunk_worker_pool_matches_single_thread(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(VALUE_ID, TYPE_PACKED_FLOAT32_ARRAY)
	ecs.create_entities(8, VALUE_ID)
	var single: _SumChunkSystem = _SumChunkSystem.new(ecs)
	single.update(0.016)
	var parallel: _SumChunkSystem = _SumChunkSystem.new(ecs)
	parallel.use_worker_pool = true
	parallel.update(0.016)
	if parallel.processed_chunks == 0:
		runner.assert_gt(single.processed_chunks, 0)
		runner.assert_eq(single.processed_entities, 8)
		return
	runner.assert_eq(parallel.processed_chunks, single.processed_chunks)
	runner.assert_eq(parallel.processed_entities, single.processed_entities)
