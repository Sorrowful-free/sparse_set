class_name ECSChunkWorkerDispatch extends RefCounted

## Единая политика WTP для chunk-систем и бенчмарков: батчинг, AUTO fallback, FORCE.

static func max_parallel_tasks() -> int:
	return maxi(1, OS.get_processor_count())

## Возвращает 0 если нужен main thread; иначе task_count >= 1.
static func compute_task_count(chunk_count: int, settings: ECSChunkParallelSettings) -> int:
	if chunk_count <= 0 or settings == null:
		return 0
	var cap: int = max_parallel_tasks()
	var chunks_per_task: int = maxi(1, settings.chunks_per_task)
	if settings.parallel_mode == ECSChunkParallelSettings.ParallelMode.FORCE:
		return mini(cap, chunk_count)
	var raw: int = ceili(float(chunk_count) / float(chunks_per_task))
	var task_count: int = mini(cap, raw)
	if task_count < maxi(1, settings.min_parallel_tasks):
		return 0
	return task_count

## true если последний run_chunks ушёл в WorkerThreadPool (для тестов).
static var last_used_worker_pool: bool = false

## Обрабатывает чанки на main thread или через strided WTP group task.
static func run_chunks(
	chunks: Array[ECSQueryChunk],
	settings: ECSChunkParallelSettings,
	chunk_callback: Callable
) -> void:
	last_used_worker_pool = false
	if chunks.is_empty():
		return
	var task_count: int = compute_task_count(chunks.size(), settings)
	if task_count <= 0:
		_run_main_thread(chunks, chunk_callback)
		return
	last_used_worker_pool = true
	var group_id: int = WorkerThreadPool.add_group_task(
		_run_strided.bind(chunks, chunk_callback, task_count),
		task_count
	)
	WorkerThreadPool.wait_for_group_task_completion(group_id)

static func _run_main_thread(chunks: Array[ECSQueryChunk], chunk_callback: Callable) -> void:
	for chunk: ECSQueryChunk in chunks:
		chunk_callback.call(chunk)

static func _run_strided(
	chunks: Array[ECSQueryChunk],
	chunk_callback: Callable,
	task_count: int,
	task_index: int
) -> void:
	var i: int = task_index
	var n: int = chunks.size()
	while i < n:
		chunk_callback.call(chunks[i])
		i += task_count
