extends RefCounted
class_name ECSBenchmark

## Имена метрик для side-by-side сравнения PGDECS vs GECS.
## Общий контракт — `addons/gecs/tests/compare_metric_names.gd` (class_name CompareMetricNames),
## но здесь они продублированы локально: pgdecs должен парситься и работать без аддона gecs.
## При изменении имён в gecs — синхронизировать здесь.
const METRIC_QUERY_E_C_SLOT := "query iterate entities+components [slot API]"
const METRIC_QUERY_E_C_FAST := "query iterate entities+components FAST [dense_slots+buffers]"
const METRIC_QUERY_E_C_WTP := "query iterate entities+components WorkerThreadPool"
const METRIC_QUERY_CHUNKS_WTP := "query.for_each_chunk WorkerThreadPool"

const POSITION_ID: int = 1
const HEALTH_ID: int = 2

var _ecs: ECSManager
var _iterations: int = 10000
var _gc_runner: ECSSystemRunner = null

class _NoOpFrameSystem extends ECSSystemBase:
	pass

func _init(ecs: ECSManager, iterations: int = 10000) -> void:
	_ecs = ecs
	_iterations = iterations

## Конец кадра как в игре: run() → flush_archetype_gc_if_pending().
func _flush_deferred_gc_via_runner() -> void:
	if _gc_runner == null:
		var noop: _NoOpFrameSystem = _NoOpFrameSystem.new(_ecs)
		_gc_runner = ECSSystemRunner.new()
		_gc_runner.add_system(noop)
	_gc_runner.run(0.0)
	if _ecs.auto_gc_archetypes:
		_ecs.flush_archetype_gc_if_pending()

func _time_block(name: String, block: Callable) -> float:
	var start: int = Time.get_ticks_usec()
	block.call()
	var end: int = Time.get_ticks_usec()
	return (end - start) / 1_000_000.0

func benchmark_create_entity() -> float:
	_ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	return _time_block("create_entity x %d" % _iterations, func():
		for i in range(_iterations):
			var eid: int = _ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	)

func benchmark_destroy_entity() -> float:
	_ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	var ids: PackedInt64Array = PackedInt64Array()
	for i in range(_iterations):
		ids.append(_ecs.create_entity_packed(PackedInt64Array([POSITION_ID])))
	return _time_block("destroy_entity x %d" % _iterations, func():
		for eid in ids:
			_ecs.destroy_entity(eid)
		_flush_deferred_gc_via_runner()
	)

func benchmark_create_entities_batch() -> float:
	_ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	var batches: int = maxi(1, _iterations / 100)
	var total: int = batches * 100
	return _time_block("create_entities(100) x %d = %d entities" % [batches, total], func():
		for i in range(batches):
			var tmp = _ecs.create_entities_packed(100, PackedInt64Array([POSITION_ID]))
	)

func benchmark_destroy_entities_batch() -> float:
	_ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	var batch_size: int = 100
	var batches: int = maxi(1, _iterations / 100)
	var all_ids: PackedInt64Array = PackedInt64Array()
	for i in range(batches):
		var ids: PackedInt64Array = _ecs.create_entities_packed(batch_size, PackedInt64Array([POSITION_ID]))
		for eid in ids:
			all_ids.append(eid)
	return _time_block("destroy_entities batch (total %d)" % all_ids.size(), func():
		_ecs.destroy_entities_packed(all_ids)
		_flush_deferred_gc_via_runner()
	)

func benchmark_query_get_entity_ids() -> float:
	_ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	_ecs.register_component(HEALTH_ID, ECSComponent.Type.PACKED_INT32)
	for i in range(_iterations):
		_ecs.create_entity_packed(PackedInt64Array([POSITION_ID, HEALTH_ID]))
	var query: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).with_component(HEALTH_ID).build(_ecs)
	var runs: int = 100
	return _time_block("query.get_entity_ids() x %d (world size %d)" % [runs, _iterations], func():
		for j in range(runs):
			var tmp = query.get_entity_ids()
		)

## Итерация по чанкам на главном потоке: for_each_chunk (alloc-free hot path).
func benchmark_query_iterate_chunks() -> float:
	_ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	_ecs.register_component(HEALTH_ID, ECSComponent.Type.PACKED_INT32)
	for i in range(_iterations):
		_ecs.create_entity_packed(PackedInt64Array([POSITION_ID, HEALTH_ID]))
	var query: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).with_component(HEALTH_ID).build(_ecs)
	var runs: int = 100
	return _time_block("query.for_each_chunk iterate x %d (world size %d)" % [runs, _iterations], func():
		for j in range(runs):
			var total: int = 0
			query.for_each_chunk(func(chunk: ECSQueryChunk) -> void:
				total += chunk.get_entity_count()
			)
		)

## Итерация по сущностям с чтением всех компонентов: get_chunks() + для каждого чанка get_component_chunk()
## и обход по слотам с чтением position и health (SoA-стиль, как в реальной системе).
func benchmark_query_iterate_entities_with_components() -> float:
	_ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	_ecs.register_component(HEALTH_ID, ECSComponent.Type.PACKED_INT32)
	for i in range(_iterations):
		_ecs.create_entity_packed(PackedInt64Array([POSITION_ID, HEALTH_ID]))
	var query: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).with_component(HEALTH_ID).build(_ecs)
	var runs: int = 100
	return _time_block("query iterate entities+components (chunks) x %d (world size %d)" % [runs, _iterations], func():
		for j in range(runs):
			var acc: float = 0.0
			query.for_each_chunk(func(chunk: ECSQueryChunk) -> void:
				var pos_chunk: ECSComponentBaseArrayChunk = chunk.get_component_chunk(POSITION_ID)
				var health_chunk: ECSComponentBaseArrayChunk = chunk.get_component_chunk(HEALTH_ID)
				if pos_chunk == null || health_chunk == null:
					return
				var pos_typed: ECSComponentVector2ArrayChunk = pos_chunk as ECSComponentVector2ArrayChunk
				var health_typed: ECSComponentInt32ArrayChunk = health_chunk as ECSComponentInt32ArrayChunk
				for i in range(chunk.get_entity_count()):
					var eid: int = chunk.get_entity_id_at(i)
					var slot: int = ECSEntityIdsUtils.slot_from_handle(eid)
					var pos: Vector2 = pos_typed.get_value_at_slot(slot)
					var health: int = health_typed.get_value_at_slot(slot)
					acc += pos.x + pos.y + float(health)
			)
		)

## То же, что iterate_entities_with_components, но через get_dense_slots() + get_values_buffer() (без per-element вызовов).
func benchmark_query_iterate_entities_with_components_fast() -> float:
	_ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	_ecs.register_component(HEALTH_ID, ECSComponent.Type.PACKED_INT32)
	for i in range(_iterations):
		_ecs.create_entity_packed(PackedInt64Array([POSITION_ID, HEALTH_ID]))
	var query: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).with_component(HEALTH_ID).build(_ecs)
	var runs: int = 100
	return _time_block("query iterate entities+components FAST x %d (world size %d)" % [runs, _iterations], func():
		for j in range(runs):
			var acc: float = 0.0
			query.for_each_chunk(func(chunk: ECSQueryChunk) -> void:
				var pos_chunk: ECSComponentBaseArrayChunk = chunk.get_component_chunk(POSITION_ID)
				var health_chunk: ECSComponentBaseArrayChunk = chunk.get_component_chunk(HEALTH_ID)
				if pos_chunk == null || health_chunk == null:
					return
				var slots: PackedInt32Array = chunk.get_dense_slots()
				var count: int = chunk.get_entity_count()
				var pos_buf: PackedVector2Array = (pos_chunk as ECSComponentVector2ArrayChunk).get_values_buffer()
				var health_buf: PackedInt32Array = (health_chunk as ECSComponentInt32ArrayChunk).get_values_buffer()
				for i in range(count):
					var slot: int = slots[i]
					var pos: Vector2 = pos_buf[slot]
					acc += pos.x + pos.y + float(health_buf[slot])
			)
		)

## Сумма по одному чанку (slot API) — callback для [ECSChunkWorkerDispatch].
static func _sum_chunk_entities_with_components(
	chunk: ECSQueryChunk,
	chunk_to_index: Dictionary,
	results: PackedFloat32Array,
	position_id: int,
	health_id: int
) -> void:
	var key: int = chunk.get_archetype_chunk().get_instance_id()
	var idx: int = int(chunk_to_index[key])
	var pos_chunk: ECSComponentBaseArrayChunk = chunk.get_component_chunk(position_id)
	var health_chunk: ECSComponentBaseArrayChunk = chunk.get_component_chunk(health_id)
	if pos_chunk == null || health_chunk == null:
		results[idx] = 0.0
		return
	var pos_typed: ECSComponentVector2ArrayChunk = pos_chunk as ECSComponentVector2ArrayChunk
	var health_typed: ECSComponentInt32ArrayChunk = health_chunk as ECSComponentInt32ArrayChunk
	var acc: float = 0.0
	for i in range(chunk.get_entity_count()):
		var eid: int = chunk.get_entity_id_at(i)
		var slot: int = ECSEntityIdsUtils.slot_from_handle(eid)
		var pos: Vector2 = pos_typed.get_value_at_slot(slot)
		var health: int = health_typed.get_value_at_slot(slot)
		acc += pos.x + pos.y + float(health)
	results[idx] = acc

static func _wtp_auto_settings() -> ECSChunkParallelSettings:
	return _wtp_settings(
		ECSChunkParallelSettings.DEFAULT_CHUNKS_PER_TASK,
		ECSChunkParallelSettings.DEFAULT_MIN_PARALLEL_TASKS,
		ECSChunkParallelSettings.ParallelMode.AUTO
	)

static func _wtp_main_fallback_settings() -> ECSChunkParallelSettings:
	## ceil(98/256)==1 при 25k сущностях → task_count < min_parallel_tasks → main thread.
	return _wtp_settings(256, ECSChunkParallelSettings.DEFAULT_MIN_PARALLEL_TASKS, ECSChunkParallelSettings.ParallelMode.AUTO)

static func _wtp_settings(
	chunks_per_task: int,
	min_parallel_tasks: int,
	mode: ECSChunkParallelSettings.ParallelMode
) -> ECSChunkParallelSettings:
	var settings: ECSChunkParallelSettings = ECSChunkParallelSettings.new()
	settings.chunks_per_task = chunks_per_task
	settings.min_parallel_tasks = min_parallel_tasks
	settings.parallel_mode = mode
	return settings

static func _build_chunk_index_map(chunks: Array[ECSQueryChunk]) -> Dictionary:
	var chunk_to_index: Dictionary = {}
	for i in range(chunks.size()):
		chunk_to_index[chunks[i].get_archetype_chunk().get_instance_id()] = i
	return chunk_to_index

static func _sum_chunk_entities_with_components_acc(
	chunk: ECSQueryChunk,
	position_id: int,
	health_id: int
) -> float:
	var pos_chunk: ECSComponentBaseArrayChunk = chunk.get_component_chunk(position_id)
	var health_chunk: ECSComponentBaseArrayChunk = chunk.get_component_chunk(health_id)
	if pos_chunk == null || health_chunk == null:
		return 0.0
	var pos_typed: ECSComponentVector2ArrayChunk = pos_chunk as ECSComponentVector2ArrayChunk
	var health_typed: ECSComponentInt32ArrayChunk = health_chunk as ECSComponentInt32ArrayChunk
	var acc: float = 0.0
	for i in range(chunk.get_entity_count()):
		var eid: int = chunk.get_entity_id_at(i)
		var slot: int = ECSEntityIdsUtils.slot_from_handle(eid)
		var pos: Vector2 = pos_typed.get_value_at_slot(slot)
		var health: int = health_typed.get_value_at_slot(slot)
		acc += pos.x + pos.y + float(health)
	return acc

static func _count_chunk_entities(
	chunk: ECSQueryChunk,
	chunk_to_index: Dictionary,
	results: PackedInt32Array
) -> void:
	var key: int = chunk.get_archetype_chunk().get_instance_id()
	var idx: int = int(chunk_to_index[key])
	results[idx] = chunk.get_entity_count()

static func _run_wtp_e_c_dispatch(
	query: ECSQuery,
	runs: int,
	settings: ECSChunkParallelSettings,
	worker_chunks: Array[ECSQueryChunk]
) -> void:
	for _run in range(runs):
		var run_count: int = query.begin_chunk_run()
		if run_count == 0:
			continue
		worker_chunks.clear()
		for i in range(run_count):
			worker_chunks.append(query.get_chunk_at_run_index(i))
		var results: PackedFloat32Array = PackedFloat32Array()
		results.resize(worker_chunks.size())
		var chunk_to_index: Dictionary = _build_chunk_index_map(worker_chunks)
		var process_chunk := func(chunk: ECSQueryChunk) -> void:
			_sum_chunk_entities_with_components(chunk, chunk_to_index, results, POSITION_ID, HEALTH_ID)
		var task_count: int = ECSChunkWorkerDispatch.compute_task_count(run_count, settings)
		if task_count <= 0:
			for chunk: ECSQueryChunk in worker_chunks:
				process_chunk.call(chunk)
		else:
			ECSChunkWorkerDispatch.run_chunks(worker_chunks, settings, process_chunk)
		var acc: float = 0.0
		for k in range(results.size()):
			acc += results[k]

static func _run_wtp_chunk_count_dispatch(
	query: ECSQuery,
	runs: int,
	settings: ECSChunkParallelSettings,
	worker_chunks: Array[ECSQueryChunk]
) -> void:
	for _run in range(runs):
		var run_count: int = query.begin_chunk_run()
		if run_count == 0:
			continue
		worker_chunks.clear()
		for i in range(run_count):
			worker_chunks.append(query.get_chunk_at_run_index(i))
		var results: PackedInt32Array = PackedInt32Array()
		results.resize(worker_chunks.size())
		var chunk_to_index: Dictionary = _build_chunk_index_map(worker_chunks)
		var process_chunk := func(chunk: ECSQueryChunk) -> void:
			_count_chunk_entities(chunk, chunk_to_index, results)
		var task_count: int = ECSChunkWorkerDispatch.compute_task_count(run_count, settings)
		if task_count <= 0:
			for chunk: ECSQueryChunk in worker_chunks:
				process_chunk.call(chunk)
		else:
			ECSChunkWorkerDispatch.run_chunks(worker_chunks, settings, process_chunk)

func _prepare_e_c_query() -> ECSQuery:
	_ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	_ecs.register_component(HEALTH_ID, ECSComponent.Type.PACKED_INT32)
	for i in range(_iterations):
		_ecs.create_entity_packed(PackedInt64Array([POSITION_ID, HEALTH_ID]))
	return ECSQueryBuilder.new().with_component(POSITION_ID).with_component(HEALTH_ID).build(_ecs)

## Прямой begin_chunk_run на main thread (без Callable в hot loop).
func benchmark_query_iterate_entities_with_components_begin_chunk_run() -> float:
	var query: ECSQuery = _prepare_e_c_query()
	var runs: int = 100
	return _time_block(
		"query iterate e+c begin_chunk_run main x %d (world %d)" % [runs, _iterations],
		func():
			for _run in range(runs):
				var acc: float = 0.0
				var run_count: int = query.begin_chunk_run()
				for i in range(run_count):
					var chunk: ECSQueryChunk = query.get_chunk_at_run_index(i)
					acc += _sum_chunk_entities_with_components_acc(chunk, POSITION_ID, HEALTH_ID)
	)

## Прямой for_each_chunk на main thread (Callable; для сравнения с begin_chunk_run).
func benchmark_query_iterate_entities_with_components_for_each_chunk_main() -> float:
	var query: ECSQuery = _prepare_e_c_query()
	var runs: int = 100
	return _time_block(
		"query iterate e+c for_each_chunk main x %d (world %d)" % [runs, _iterations],
		func():
			for _run in range(runs):
				var acc: float = 0.0
				query.for_each_chunk(func(chunk: ECSQueryChunk) -> void:
					acc += _sum_chunk_entities_with_components_acc(chunk, POSITION_ID, HEALTH_ID)
				)
	)

## Итерация по сущностям через ECSChunkWorkerDispatch (настраиваемые settings).
func benchmark_query_iterate_entities_with_components_worker_pool_settings(
	settings: ECSChunkParallelSettings,
	metric_label: String
) -> float:
	var query: ECSQuery = _prepare_e_c_query()
	var runs: int = 100
	var worker_chunks: Array[ECSQueryChunk] = []
	return _time_block(
		"%s x %d (world size %d)" % [metric_label, runs, _iterations],
		func():
			_run_wtp_e_c_dispatch(query, runs, settings, worker_chunks)
	)

## Итерация по сущностям с чтением всех компонентов через WorkerThreadPool (ECSChunkWorkerDispatch AUTO cpt=8).
func benchmark_query_iterate_entities_with_components_worker_pool() -> float:
	return benchmark_query_iterate_entities_with_components_worker_pool_settings(
		_wtp_auto_settings(),
		"query iterate entities+components WorkerThreadPool [AUTO cpt=8]"
	)

## AUTO cpt=256: одна задача < min_parallel_tasks → dispatch уходит на main thread.
func benchmark_query_iterate_entities_with_components_worker_pool_main_fallback() -> float:
	return benchmark_query_iterate_entities_with_components_worker_pool_settings(
		_wtp_main_fallback_settings(),
		"query iterate entities+components WorkerThreadPool [AUTO cpt=256 main-fallback]"
	)

## Обработка чанков через ECSChunkWorkerDispatch (настраиваемые settings).
func benchmark_query_worker_pool_settings(
	settings: ECSChunkParallelSettings,
	metric_label: String
) -> float:
	var query: ECSQuery = _prepare_e_c_query()
	var runs: int = 100
	var worker_chunks: Array[ECSQueryChunk] = []
	return _time_block(
		"%s x %d (world %d)" % [metric_label, runs, _iterations],
		func():
			_run_wtp_chunk_count_dispatch(query, runs, settings, worker_chunks)
	)

## Обработка чанков через WorkerThreadPool (ECSChunkWorkerDispatch AUTO cpt=8).
func benchmark_query_worker_pool() -> float:
	return benchmark_query_worker_pool_settings(
		_wtp_auto_settings(),
		"query.for_each_chunk WorkerThreadPool [AUTO cpt=8]"
	)

## AUTO cpt=256 → main thread через dispatch.
func benchmark_query_worker_pool_main_fallback() -> float:
	return benchmark_query_worker_pool_settings(
		_wtp_main_fallback_settings(),
		"query.for_each_chunk WorkerThreadPool [AUTO cpt=256 main-fallback]"
	)

func benchmark_add_remove_component() -> float:
	_ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	_ecs.register_component(HEALTH_ID, ECSComponent.Type.PACKED_INT32)
	var eid: int = _ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	var runs: int = min(_iterations, 5000)
	return _time_block("add_component + remove_component x %d" % runs, func():
		for i in range(runs):
			_ecs.add_component(eid, HEALTH_ID)
			_ecs.remove_component(eid, HEALTH_ID)
		_flush_deferred_gc_via_runner()
	)

func benchmark_command_buffer_execute() -> float:
	_ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	var buf: ECSCommandBuffer = ECSCommandBuffer.new(_ecs)
	var cids: PackedInt64Array = PackedInt64Array([POSITION_ID])
	var batch: int = 1000
	for i in range(batch):
		buf.create_entity_packed(cids)
	return _time_block("command_buffer execute (%d create_entity)" % batch, func():
		buf.execute()
	)

func benchmark_command_buffer_coalescing_frame() -> float:
	_ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	_ecs.register_component(HEALTH_ID, ECSComponent.Type.PACKED_INT32)
	var cycles: int = maxi(1, _iterations / 25)
	var pos_only: PackedInt64Array = PackedInt64Array([POSITION_ID])
	var survivors: PackedInt64Array = PackedInt64Array()
	survivors.resize(cycles)
	for i in range(cycles):
		survivors[i] = _ecs.create_entity_packed(pos_only)
	var buf: ECSCommandBuffer = ECSCommandBuffer.new(_ecs)
	for i in range(cycles):
		var temp_id: int = buf.create_entity_packed(pos_only)
		buf.destroy_entity(temp_id)
		var eid: int = survivors[i]
		buf.add_component(eid, HEALTH_ID)
		buf.remove_component(eid, HEALTH_ID)
	for i in range(cycles):
		buf.destroy_entity(survivors[i])
	var raw_cmds: int = cycles * 5
	return _time_block(
		"command_buffer coalescing frame (%d cycles, %d raw cmds)" % [cycles, raw_cmds],
		func():
			buf.execute()
			_flush_deferred_gc_via_runner()
	)

class _ChangeDetectChunkSystem extends ECSSystemChunkBase:
	const _POSITION_ID: int = 1
	const _HEALTH_ID: int = 2
	var touched: int = 0

	func _build_query() -> ECSQuery:
		return ECSQueryBuilder.new().with_component(_POSITION_ID).with_component(_HEALTH_ID).build(get_ecs_manager())

	func process_chunk(_chunk: ECSQueryChunk, _delta: float) -> void:
		touched += 1

class _HeavyReadChunkSystem extends ECSSystemChunkBase:
	const _POSITION_ID: int = 1
	const _HEALTH_ID: int = 2
	var processed_chunks: int = 0
	var acc: float = 0.0

	func _build_query() -> ECSQuery:
		return ECSQueryBuilder.new().with_component(_POSITION_ID).with_component(_HEALTH_ID).build(get_ecs_manager())

	func process_chunk(chunk: ECSQueryChunk, _delta: float) -> void:
		processed_chunks += 1
		var pos_chunk: ECSComponentVector2ArrayChunk = chunk.get_component_chunk(_POSITION_ID) as ECSComponentVector2ArrayChunk
		var health_chunk: ECSComponentInt32ArrayChunk = chunk.get_component_chunk(_HEALTH_ID) as ECSComponentInt32ArrayChunk
		if pos_chunk == null || health_chunk == null:
			return
		var count: int = chunk.get_entity_count()
		var dense: PackedInt64Array = chunk.get_dense_entities()
		for i in range(count):
			var slot: int = ECSEntityIdsUtils.slot_from_handle(dense[i])
			var pos: Vector2 = pos_chunk.get_value_at_slot(slot)
			acc += pos.x + pos.y + float(health_chunk.get_value_at_slot(slot))

func benchmark_system_change_detection() -> float:
	_ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	_ecs.register_component(HEALTH_ID, ECSComponent.Type.PACKED_INT32)
	for i in range(_iterations):
		_ecs.create_entity_packed(PackedInt64Array([POSITION_ID, HEALTH_ID]))
	var system: _ChangeDetectChunkSystem = _ChangeDetectChunkSystem.new(_ecs)
	system.change_detection = true
	system.update(0.016)
	var runs: int = 100
	return _time_block("system change_detection steady (no writes) x %d (world %d)" % [runs, _iterations], func():
		for j in range(runs):
			system.update(0.016)
	)

## ~2% сущностей в случайных чанках (размазанные изменения); read-only heavy process_chunk.
func benchmark_system_change_detection_sparse_scattered(use_change_detection: bool) -> float:
	_ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	_ecs.register_component(HEALTH_ID, ECSComponent.Type.PACKED_INT32)
	var ids: PackedInt64Array = PackedInt64Array()
	ids.resize(_iterations)
	for i in range(_iterations):
		ids[i] = _ecs.create_entity_packed(PackedInt64Array([POSITION_ID, HEALTH_ID]))
	var pos: ECSComponentVector2Array = _ecs.get_component_array(POSITION_ID) as ECSComponentVector2Array
	var system: _HeavyReadChunkSystem = _HeavyReadChunkSystem.new(_ecs)
	system.change_detection = use_change_detection
	var touches_per_frame: int = maxi(1, _iterations / 50)
	var runs: int = 100
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 12345
	var label: String = "ON" if use_change_detection else "OFF"
	return _time_block(
		"system change_detection scattered %s (~%d rand writes/frame) x %d" % [label, touches_per_frame, runs],
		func():
			system.update(0.016)
			for j in range(runs):
				for k in range(touches_per_frame):
					var eid: int = ids[rng.randi() % ids.size()]
					pos.set_component(eid, Vector2(float(j + k), float(k)))
				system.update(0.016)
	)

## 1–2 «горячих» чанка за кадр (локальная активность); типичный игровой паттерн.
func benchmark_system_change_detection_hot_chunks(use_change_detection: bool) -> float:
	_ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	_ecs.register_component(HEALTH_ID, ECSComponent.Type.PACKED_INT32)
	var ids: PackedInt64Array = PackedInt64Array()
	ids.resize(_iterations)
	for i in range(_iterations):
		ids[i] = _ecs.create_entity_packed(PackedInt64Array([POSITION_ID, HEALTH_ID]))
	var pos: ECSComponentVector2Array = _ecs.get_component_array(POSITION_ID) as ECSComponentVector2Array
	var system: _HeavyReadChunkSystem = _HeavyReadChunkSystem.new(_ecs)
	system.change_detection = use_change_detection
	var chunk_size: int = ECSEntityIdsUtils.CHUNK_SIZE
	var chunk_count: int = maxi(1, (ids.size() + chunk_size - 1) / chunk_size)
	var hot_chunks_per_frame: int = 2
	var touches_per_hot_chunk: int = 32
	var runs: int = 100
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 54321
	var label: String = "ON" if use_change_detection else "OFF"
	return _time_block(
		"system change_detection hot-chunks %s (%d chunks x %d writes/frame) x %d (world %d)" % [
			label, hot_chunks_per_frame, touches_per_hot_chunk, runs, _iterations],
		func():
			system.update(0.016)
			for j in range(runs):
				for h in range(hot_chunks_per_frame):
					var ci: int = rng.randi() % chunk_count
					var base: int = ci * chunk_size
					var in_chunk: int = mini(chunk_size, ids.size() - base)
					if in_chunk <= 0:
						continue
					for k in range(touches_per_hot_chunk):
						var eid: int = ids[base + rng.randi() % in_chunk]
						pos.set_component(eid, Vector2(float(j + h + k), float(k)))
				system.update(0.016)
	)

func _record_metric(results: Dictionary, name: String, seconds: float) -> void:
	results[name] = seconds
	print("  %s: %.3f s" % [name, seconds])

func run_all() -> Dictionary:
	var results: Dictionary = {}
	print("--- ECS Performance (iterations=%d) ---" % _iterations)
	var ecs_fresh: ECSManager = ECSManager.new()
	var bench: ECSBenchmark = ECSBenchmark.new(ecs_fresh, _iterations)

	_record_metric(results, "create_entity", bench.benchmark_create_entity())

	ecs_fresh = ECSManager.new()
	bench = ECSBenchmark.new(ecs_fresh, _iterations)
	_record_metric(results, "destroy_entity", bench.benchmark_destroy_entity())

	ecs_fresh = ECSManager.new()
	bench = ECSBenchmark.new(ecs_fresh, _iterations)
	_record_metric(results, "create_entities batch", bench.benchmark_create_entities_batch())

	ecs_fresh = ECSManager.new()
	bench = ECSBenchmark.new(ecs_fresh, _iterations)
	_record_metric(results, "destroy_entities batch", bench.benchmark_destroy_entities_batch())

	ecs_fresh = ECSManager.new()
	bench = ECSBenchmark.new(ecs_fresh, _iterations)
	_record_metric(results, "query.get_entity_ids", bench.benchmark_query_get_entity_ids())

	ecs_fresh = ECSManager.new()
	bench = ECSBenchmark.new(ecs_fresh, _iterations)
	_record_metric(results, "query.for_each_chunk iterate", bench.benchmark_query_iterate_chunks())

	ecs_fresh = ECSManager.new()
	bench = ECSBenchmark.new(ecs_fresh, _iterations)
	_record_metric(
		results,
		METRIC_QUERY_E_C_SLOT,
		bench.benchmark_query_iterate_entities_with_components()
	)

	ecs_fresh = ECSManager.new()
	bench = ECSBenchmark.new(ecs_fresh, _iterations)
	_record_metric(
		results,
		METRIC_QUERY_E_C_FAST,
		bench.benchmark_query_iterate_entities_with_components_fast()
	)

	ecs_fresh = ECSManager.new()
	bench = ECSBenchmark.new(ecs_fresh, _iterations)
	_record_metric(
		results,
		METRIC_QUERY_E_C_WTP,
		bench.benchmark_query_iterate_entities_with_components_worker_pool()
	)

	ecs_fresh = ECSManager.new()
	bench = ECSBenchmark.new(ecs_fresh, _iterations)
	_record_metric(
		results,
		METRIC_QUERY_CHUNKS_WTP,
		bench.benchmark_query_worker_pool()
	)

	ecs_fresh = ECSManager.new()
	bench = ECSBenchmark.new(ecs_fresh, _iterations)
	_record_metric(results, "add/remove_component", bench.benchmark_add_remove_component())

	ecs_fresh = ECSManager.new()
	bench = ECSBenchmark.new(ecs_fresh, _iterations)
	_record_metric(results, "command_buffer execute", bench.benchmark_command_buffer_execute())

	ecs_fresh = ECSManager.new()
	bench = ECSBenchmark.new(ecs_fresh, _iterations)
	_record_metric(results, "command_buffer coalescing frame", bench.benchmark_command_buffer_coalescing_frame())

	ecs_fresh = ECSManager.new()
	bench = ECSBenchmark.new(ecs_fresh, _iterations)
	_record_metric(results, "system change_detection steady", bench.benchmark_system_change_detection())

	ecs_fresh = ECSManager.new()
	bench = ECSBenchmark.new(ecs_fresh, _iterations)
	_record_metric(results, "system change_detection scattered ON", bench.benchmark_system_change_detection_sparse_scattered(true))

	ecs_fresh = ECSManager.new()
	bench = ECSBenchmark.new(ecs_fresh, _iterations)
	_record_metric(results, "system change_detection scattered OFF", bench.benchmark_system_change_detection_sparse_scattered(false))

	ecs_fresh = ECSManager.new()
	bench = ECSBenchmark.new(ecs_fresh, _iterations)
	_record_metric(results, "system change_detection hot-chunks ON", bench.benchmark_system_change_detection_hot_chunks(true))

	ecs_fresh = ECSManager.new()
	bench = ECSBenchmark.new(ecs_fresh, _iterations)
	_record_metric(results, "system change_detection hot-chunks OFF", bench.benchmark_system_change_detection_hot_chunks(false))

	return results

func run_change_detection_hot() -> void:
	print("--- ECS Performance (iterations=%d) ---" % _iterations)
	var ecs_fresh: ECSManager = ECSManager.new()
	var t: float = ECSBenchmark.new(ecs_fresh, _iterations).benchmark_system_change_detection()
	print("  system change_detection steady: %.3f s" % t)
	ecs_fresh = ECSManager.new()
	t = ECSBenchmark.new(ecs_fresh, _iterations).benchmark_system_change_detection_sparse_scattered(true)
	print("  system change_detection scattered ON: %.3f s" % t)
	ecs_fresh = ECSManager.new()
	t = ECSBenchmark.new(ecs_fresh, _iterations).benchmark_system_change_detection_sparse_scattered(false)
	print("  system change_detection scattered OFF: %.3f s" % t)
	ecs_fresh = ECSManager.new()
	t = ECSBenchmark.new(ecs_fresh, _iterations).benchmark_system_change_detection_hot_chunks(true)
	print("  system change_detection hot-chunks ON: %.3f s" % t)
	ecs_fresh = ECSManager.new()
	t = ECSBenchmark.new(ecs_fresh, _iterations).benchmark_system_change_detection_hot_chunks(false)
	print("  system change_detection hot-chunks OFF: %.3f s" % t)
