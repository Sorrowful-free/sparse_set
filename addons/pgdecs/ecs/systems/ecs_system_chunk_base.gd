@abstract
class_name ECSSystemChunkBase extends ECSSystemBase

## Базовый класс системы с итерацией по чанкам query.
## Наследник обязан реализовать [method build_query] (вызывается из [method _init]) и [method process_chunk]:
## в нём обрабатывается один чанк (SoA через [method ECSQueryChunk.get_component_chunk]).
## При [member use_worker_pool] == true чанки собираются через [method ECSQuery.begin_chunk_run]
## и обрабатываются через [WorkerThreadPool]; в этом случае [method process_chunk] не должен вызывать
## [method get_command_buffer] (только чтение данных).
##
## [b]Порядок в [method _init] наследника:[/b] [method build_query] вызывается внутри [code]super(...)[/code],
## поэтому поля, которые наследник присваивает [b]после[/b] [code]super(...)[/code], в момент построения
## query ещё не установлены (компилятор этого не ловит — это рантайм-порядок, а не ошибка парсера).
## Если [method build_query] читает поля инстанса — присваивайте их [b]до[/b] [code]super(...)[/code].
## [method get_ecs_manager] доступен всегда: база выставляет его до вызова [method build_query].

var _query: ECSQuery
var _worker_chunks: Array[ECSQueryChunk] = []

## Если true, process_chunk вызывается только для чанков, изменившихся с прошлого process_system
## (структурно или по значениям компонентов query). По умолчанию false — без оверхеда.
var change_detection: bool = false

## key: instance_id archetype-чанка -> [struct_ver, val_ver(c0), val_ver(c1), ...]
var _chunk_seen: Dictionary[int, PackedInt64Array] = {}
var _version_scratch: PackedInt64Array = PackedInt64Array()

## Если true, чанки обрабатываются параллельно через WorkerThreadPool (только чтение в process_chunk).
var use_worker_pool: bool = false

## Per-system политика WTP: батчинг, AUTO fallback, FORCE для тяжёлой логики.
var parallel_settings: ECSChunkParallelSettings = ECSChunkParallelSettings.new()

func _init(ecs_manager: ECSManager) -> void:
	super._init(ecs_manager)
	_query = build_query()
	if _query == null:
		push_warning("ECSSystemChunkBase: build_query() returned null in %s" % get_script())

## Переопределяйте в наследниках: создайте и верните query через [ECSQueryBuilder].build(get_ecs_manager()).
## Возврат null — ошибка конфигурации: [method _init] выдаст push_warning, а [method process_system] будет no-op.
@abstract func build_query() -> ECSQuery

func get_query() -> ECSQuery:
	return _query

## Вызывается раннером каждый кадр: получает чанки query и для каждого вызывает [method process_chunk].
func process_system(delta: float) -> void:
	if _query == null:
		return
	if use_worker_pool:
		_run_worker_pool_update(delta)
	else:
		_run_main_thread_update(delta)
	if change_detection:
		_prune_stale_chunk_seen()

func _run_main_thread_update(delta: float) -> void:
	var run_count: int = _query.begin_chunk_run()
	for i in range(run_count):
		var chunk: ECSQueryChunk = _query.get_chunk_at_run_index(i)
		if change_detection and not _consume_chunk_dirty(chunk):
			continue
		process_chunk(chunk, delta)

func _run_worker_pool_update(delta: float) -> void:
	var run_count: int = _prepare_worker_chunks_for_run()
	if run_count == 0:
		return
	var task_count: int = ECSChunkWorkerDispatch.compute_task_count(run_count, parallel_settings)
	if task_count <= 0:
		for chunk: ECSQueryChunk in _worker_chunks:
			process_chunk(chunk, delta)
		return
	ECSChunkWorkerDispatch.run_chunks_for_system(self, _worker_chunks, delta, parallel_settings)

func _prepare_worker_chunks_for_run() -> int:
	_worker_chunks.clear()
	var run_count: int = _query.begin_chunk_run()
	for i in range(run_count):
		var chunk: ECSQueryChunk = _query.get_chunk_at_run_index(i)
		if change_detection:
			if _consume_chunk_dirty(chunk):
				_worker_chunks.append(chunk)
		else:
			_worker_chunks.append(chunk)
	return _worker_chunks.size()

## Обрабатывает один чанк. Переопределяйте в наследниках.
##
## Правило итерации:
## - Только чтение/запись значений, без create/destroy/add/remove в этом проходе →
##   [b]fast-path[/b]: [code]get_dense_slots()[/code] + [code]get_values_buffer()[/code].
## - Create/destroy, смена набора компонентов или нужен handle →
##   [b]slot API[/b]: [code]slot_from_handle(dense[i])[/code] или [code]get_component(entity_id)[/code].
##
## Fast-path (движение, физика, AI без spawn в том же проходе):
## [codeblock]
## var slots := chunk.get_dense_slots()
## var buf := comp.get_values_buffer()
## for i in range(chunk.get_entity_count()):
##     var slot := slots[i]
##     comp.set_value_at_slot(slot, buf[slot] + delta)
## [/codeblock]
##
## Slot API (нужен handle для command buffer):
## [codeblock]
## var dense := chunk.get_dense_entities()
## for i in range(chunk.get_entity_count()):
##     var slot := ECSEntityIdsUtils.slot_from_handle(dense[i])
## [/codeblock]
##
## При [member change_detection] == true пропускаются неизменённые чанки (last-seen по версиям).
## После каждого process_system записи для чанков, исчезнувших из query, удаляются из [member _chunk_seen].
## При [member use_worker_pool] == true не вызывайте [method get_command_buffer] — только чтение.
@abstract func process_chunk(_chunk: ECSQueryChunk, _delta: float) -> void

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
		_store_version_snapshot(key)
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
	_store_version_snapshot(key)
	return true

func _store_version_snapshot(key: int) -> void:
	if !_chunk_seen.has(key):
		var stored: PackedInt64Array = PackedInt64Array()
		stored.resize(_version_scratch.size())
		_chunk_seen[key] = stored
	var seen: PackedInt64Array = _chunk_seen[key]
	if seen.size() != _version_scratch.size():
		seen.resize(_version_scratch.size())
	for i in range(_version_scratch.size()):
		seen[i] = _version_scratch[i]

func _prune_stale_chunk_seen() -> void:
	if _chunk_seen.is_empty():
		return
	var active: Dictionary[int, bool] = {}
	_query.collect_active_chunk_instance_ids(active)
	var stale: Array[int] = []
	for key: int in _chunk_seen:
		if !active.has(key):
			stale.append(key)
	for key: int in stale:
		_chunk_seen.erase(key)
