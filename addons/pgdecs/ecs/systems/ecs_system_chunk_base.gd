class_name ECSSystemChunkBase extends ECSSystemBase

## Базовый класс системы с итерацией по чанкам query.
## В [method _init] переопределите [method _build_query] и создайте query через [ECSQueryBuilder].
## Переопределите [method process_chunk]: в нём обрабатывайте один чанк (SoA через [method ECSQueryChunk.get_component_chunk]).
## При [member use_worker_pool] == true чанки обрабатываются через [WorkerThreadPool]; в этом случае
## [method process_chunk] не должен вызывать [method get_command_buffer] (только чтение данных).

var _query: ECSQuery

## Если true, чанки обрабатываются параллельно через WorkerThreadPool (только чтение в process_chunk).
var use_worker_pool: bool = false

func _init(ecs_manager: ECSManager) -> void:
	super._init(ecs_manager)
	_query = _build_query()

## Переопределяйте в наследниках: создайте и верните query через [ECSQueryBuilder].build(get_ecs_manager()).
func _build_query() -> ECSQuery:
	return null

func get_query() -> ECSQuery:
	return _query

## Вызывается раннером каждый кадр: получает чанки query и для каждого вызывает [method process_chunk].
func update(delta: float) -> void:
	if _query == null:
		return
	if use_worker_pool:
		var chunks: Array[ECSQueryChunk] = _query.get_chunks()
		if chunks.is_empty():
			return
		var group_id: int = WorkerThreadPool.add_group_task(_run_chunk_for_index.bind(chunks, delta), chunks.size())
		WorkerThreadPool.wait_for_group_task_completion(group_id)
	else:
		_query.for_each_chunk(func(chunk: ECSQueryChunk) -> void:
			process_chunk(chunk, delta)
		)

## Обрабатывает один чанк. Переопределяйте в наследниках.
## Рекомендуемый hot path:
## [codeblock]
## var count := chunk.get_entity_count()
## var dense := chunk.get_dense_entities()
## var comp := chunk.get_component_chunk(MY_ID) as ECSComponentFloat32ArrayChunk
## for i in range(count):
##     var slot := ECSEntityIdsUtils.slot_from_handle(dense[i])
##     var value := comp.get_value_at_slot(slot)
## [/codeblock]
## При [member use_worker_pool] == true не вызывайте [method get_command_buffer] — только чтение.
func process_chunk(_chunk: ECSQueryChunk, _delta: float) -> void:
	pass

func _run_chunk_for_index(chunks: Array[ECSQueryChunk], delta: float, index: int) -> void:
	process_chunk(chunks[index], delta)
