class_name ECSSystemChunkBase extends ECSSystemBase

## Базовый класс системы с итерацией по чанкам query.
## В [method _init] переопределите [method _build_query] и создайте query через [ECSQueryBuilder].
## Переопределите [method process_chunk]: в нём обрабатывайте один чанк (SoA через [method ECSQueryChunk.get_component_chunk]).
## При [member use_worker_pool] == true чанки собираются через [method ECSQuery.collect_chunks]
## ([method ECSQuery.for_each_chunk] под капотом) и обрабатываются через [WorkerThreadPool]; в этом случае
## [method process_chunk] не должен вызывать [method get_command_buffer] (только чтение данных).

var _query: ECSQuery
var _worker_chunks: Array[ECSQueryChunk] = []

## Если true, process_chunk вызывается только для чанков, изменившихся с прошлого update
## (структурно или по значениям компонентов query). По умолчанию false — без оверхеда.
var change_detection: bool = false

## key: instance_id archetype-чанка -> [struct_ver, val_ver(c0), val_ver(c1), ...]
var _chunk_seen: Dictionary[int, PackedInt64Array] = {}
var _version_scratch: PackedInt64Array = PackedInt64Array()

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
		if change_detection:
			_collect_dirty_chunks(_worker_chunks)
		else:
			_query.collect_chunks(_worker_chunks)
		if _worker_chunks.is_empty():
			return
		var group_id: int = WorkerThreadPool.add_group_task(_run_chunk_for_index.bind(_worker_chunks, delta), _worker_chunks.size())
		WorkerThreadPool.wait_for_group_task_completion(group_id)
	else:
		if change_detection:
			_query.for_each_chunk(func(chunk: ECSQueryChunk) -> void:
				if _consume_chunk_dirty(chunk):
					process_chunk(chunk, delta)
			)
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
## При [member change_detection] == true пропускаются неизменённые чанки (last-seen по версиям).
## Записи для исчезнувших чанков остаются в [member _chunk_seen] (некритичная утечка памяти).
## При [member use_worker_pool] == true не вызывайте [method get_command_buffer] — только чтение.
func process_chunk(_chunk: ECSQueryChunk, _delta: float) -> void:
	pass

func _run_chunk_for_index(chunks: Array[ECSQueryChunk], delta: float, index: int) -> void:
	process_chunk(chunks[index], delta)

func _collect_dirty_chunks(out_chunks: Array[ECSQueryChunk]) -> void:
	out_chunks.clear()
	_query.for_each_chunk(func(chunk: ECSQueryChunk) -> void:
		if _consume_chunk_dirty(chunk):
			out_chunks.append(chunk)
	)

## true, если чанк изменился с прошлого вызова; обновляет сохранённые версии.
func _consume_chunk_dirty(chunk: ECSQueryChunk) -> bool:
	var component_ids: PackedInt64Array = _query.get_component_ids()
	var n: int = component_ids.size()
	_version_scratch.resize(n + 1)
	_version_scratch[0] = chunk.get_structural_version()
	for i in range(n):
		_version_scratch[i + 1] = chunk.get_component_version(component_ids[i])
	var key: int = chunk.get_archetype_chunk().get_instance_id()
	if !_chunk_seen.has(key):
		_chunk_seen[key] = _version_scratch.duplicate()
		return true
	var seen: PackedInt64Array = _chunk_seen[key]
	if seen.size() == _version_scratch.size():
		var same: bool = true
		for i in range(_version_scratch.size()):
			if seen[i] != _version_scratch[i]:
				same = false
				break
		if same:
			return false
	_chunk_seen[key] = _version_scratch.duplicate()
	return true
