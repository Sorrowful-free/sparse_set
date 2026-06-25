class_name ECSChunkParallelSettings extends Resource

## Per-system настройки параллельной обработки чанков через WorkerThreadPool.
##
## Задаётся на [ECSSystemChunkBase.parallel_settings] или через [ECSChunkSystemStrategy].
##
## - [member chunks_per_task] — в режиме AUTO: сколько чанков батчить на одну WTP-задачу.
## - [member min_parallel_tasks] — в режиме AUTO: если задач меньше — fallback на main thread.
## - [member parallel_mode] — AUTO (лёгкие системы) или FORCE (тяжёлая логика в process_chunk).

enum ParallelMode {
	## Батчинг по [member chunks_per_task]; main thread если задач < [member min_parallel_tasks].
	AUTO,
	## Максимум параллелизма: task_count = min(CPU, chunk_count); min_parallel_tasks игнорируется.
	FORCE,
}

const DEFAULT_CHUNKS_PER_TASK: int = 8
const DEFAULT_MIN_PARALLEL_TASKS: int = 2

@export_range(1, 256, 1) var chunks_per_task: int = DEFAULT_CHUNKS_PER_TASK
@export_range(1, 32, 1) var min_parallel_tasks: int = DEFAULT_MIN_PARALLEL_TASKS
@export var parallel_mode: ParallelMode = ParallelMode.AUTO
