extends GutTest

class _CountChunkSystem extends ECSSystemChunkBase:
	var seen_indices: Dictionary = {}

	func _build_query() -> ECSQuery:
		return null

	func process_chunk(chunk: ECSQueryChunk, _delta: float) -> void:
		seen_indices[chunk.get_chunk_index()] = true

func _auto_settings(chunks_per_task: int = 8, min_tasks: int = 2) -> ECSChunkParallelSettings:
	var settings: ECSChunkParallelSettings = ECSChunkParallelSettings.new()
	settings.chunks_per_task = chunks_per_task
	settings.min_parallel_tasks = min_tasks
	settings.parallel_mode = ECSChunkParallelSettings.ParallelMode.AUTO
	return settings

func _force_settings() -> ECSChunkParallelSettings:
	var settings: ECSChunkParallelSettings = ECSChunkParallelSettings.new()
	settings.parallel_mode = ECSChunkParallelSettings.ParallelMode.FORCE
	return settings

func test_compute_auto_one_chunk_falls_back() -> void:
	assert_eq(ECSChunkWorkerDispatch.compute_task_count(1, _auto_settings()), 0)

func test_compute_auto_sixteen_chunks_two_tasks() -> void:
	var cap: int = ECSChunkWorkerDispatch.max_parallel_tasks()
	var expected: int = mini(cap, ceili(16.0 / 8.0))
	assert_eq(ECSChunkWorkerDispatch.compute_task_count(16, _auto_settings()), expected)

func test_compute_auto_ninety_eight_chunks_batched() -> void:
	var cap: int = ECSChunkWorkerDispatch.max_parallel_tasks()
	var expected: int = mini(cap, ceili(98.0 / 8.0))
	assert_eq(ECSChunkWorkerDispatch.compute_task_count(98, _auto_settings()), expected)

func test_compute_force_three_chunks_ignores_batch_size() -> void:
	var cap: int = ECSChunkWorkerDispatch.max_parallel_tasks()
	assert_eq(ECSChunkWorkerDispatch.compute_task_count(3, _force_settings()), mini(cap, 3))

func test_run_chunks_main_thread_covers_all_indices() -> void:
	var chunks: Array[ECSQueryChunk] = []
	for i in range(5):
		chunks.append(ECSQueryChunk.new(null, null, i))
	var seen: Dictionary = {}
	ECSChunkWorkerDispatch.run_chunks(
		chunks,
		_auto_settings(8, 99),
		func(chunk: ECSQueryChunk) -> void:
			seen[chunk.get_chunk_index()] = true
	)
	assert_false(ECSChunkWorkerDispatch.last_used_worker_pool)
	assert_eq(seen.size(), 5)

func test_run_chunks_force_uses_worker_pool_for_single_chunk() -> void:
	var chunks: Array[ECSQueryChunk] = []
	chunks.append(ECSQueryChunk.new(null, null, 0))
	ECSChunkWorkerDispatch.run_chunks(
		chunks,
		_force_settings(),
		func(_chunk: ECSQueryChunk) -> void:
			pass
	)
	assert_true(ECSChunkWorkerDispatch.last_used_worker_pool)

func test_run_chunks_for_system_covers_all_indices() -> void:
	var chunks: Array[ECSQueryChunk] = []
	for i in range(5):
		chunks.append(ECSQueryChunk.new(null, null, i))
	var ecs: ECSManager = ECSManager.new()
	var system: _CountChunkSystem = _CountChunkSystem.new(ecs)
	ECSChunkWorkerDispatch.run_chunks_for_system(
		system,
		chunks,
		0.016,
		_auto_settings(8, 99)
	)
	assert_false(ECSChunkWorkerDispatch.last_used_worker_pool)
	assert_eq(system.seen_indices.size(), 5)
