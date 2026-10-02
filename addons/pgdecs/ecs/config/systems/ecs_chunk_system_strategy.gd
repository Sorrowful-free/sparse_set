@abstract
class_name ECSChunkSystemStrategy extends ECSSystemStrategy

## Базовая strategy для [ECSSystemChunkBase]: WTP и parallel settings через inspector.

@export var use_worker_pool: bool = false
@export var change_detection: bool = false
@export var parallel_settings: ECSChunkParallelSettings

func _apply_chunk_system_settings(system: ECSSystemChunkBase) -> void:
	system.use_worker_pool = use_worker_pool
	system.change_detection = change_detection
	if parallel_settings != null:
		system.parallel_settings = parallel_settings.duplicate()
