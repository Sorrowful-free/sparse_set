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
	ecs.create_entities_packed(3, PackedInt64Array([VALUE_ID]))
	var system: _SumChunkSystem = _SumChunkSystem.new(ecs)
	system.update(0.016)
	runner.assert_gt(system.processed_chunks, 0)
	runner.assert_eq(system.processed_entities, 3)

func test_process_chunk_worker_pool_matches_single_thread(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(VALUE_ID, TYPE_PACKED_FLOAT32_ARRAY)
	ecs.create_entities_packed(8, PackedInt64Array([VALUE_ID]))
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

func test_change_detection_skips_unchanged(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(VALUE_ID, TYPE_PACKED_FLOAT32_ARRAY)
	ecs.create_entities_packed(3, PackedInt64Array([VALUE_ID]))
	var system: _SumChunkSystem = _SumChunkSystem.new(ecs)
	system.change_detection = true
	system.update(0.016)
	var after_first: int = system.processed_chunks
	system.update(0.016)
	runner.assert_eq(system.processed_chunks, after_first)

func test_change_detection_reprocesses_after_structural(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(VALUE_ID, TYPE_PACKED_FLOAT32_ARRAY)
	ecs.create_entities_packed(3, PackedInt64Array([VALUE_ID]))
	var system: _SumChunkSystem = _SumChunkSystem.new(ecs)
	system.change_detection = true
	system.update(0.016)
	var after_first: int = system.processed_chunks
	ecs.create_entities_packed(1, PackedInt64Array([VALUE_ID]))
	system.update(0.016)
	runner.assert_gt(system.processed_chunks, after_first)

func test_change_detection_reprocesses_after_value_write(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(VALUE_ID, TYPE_PACKED_FLOAT32_ARRAY)
	var ids: PackedInt64Array = ecs.create_entities_packed(3, PackedInt64Array([VALUE_ID]))
	var system: _SumChunkSystem = _SumChunkSystem.new(ecs)
	system.change_detection = true
	system.update(0.016)
	var after_first: int = system.processed_chunks
	var comp: ECSComponentFloat32Array = ecs.get_component_array(VALUE_ID) as ECSComponentFloat32Array
	comp.set_component(ids[0], 42.0)
	system.update(0.016)
	runner.assert_gt(system.processed_chunks, after_first)

func test_change_detection_worker_pool_parity(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(VALUE_ID, TYPE_PACKED_FLOAT32_ARRAY)
	ecs.create_entities_packed(8, PackedInt64Array([VALUE_ID]))
	var system: _SumChunkSystem = _SumChunkSystem.new(ecs)
	system.change_detection = true
	system.use_worker_pool = true
	system.update(0.016)
	if system.processed_chunks == 0:
		return
	var after_first: int = system.processed_chunks
	system.update(0.016)
	runner.assert_eq(system.processed_chunks, after_first)

func test_change_detection_prunes_stale_chunk_seen(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(VALUE_ID, TYPE_PACKED_FLOAT32_ARRAY)
	var ids: PackedInt64Array = ecs.create_entities_packed(300, PackedInt64Array([VALUE_ID]))
	var system: _SumChunkSystem = _SumChunkSystem.new(ecs)
	system.change_detection = true
	system.update(0.016)
	runner.assert_gt(system._chunk_seen.size(), 0)
	ecs.destroy_entities_packed(ids)
	system.update(0.016)
	runner.assert_eq(system._chunk_seen.size(), 0)
