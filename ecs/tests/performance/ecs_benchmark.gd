extends RefCounted
class_name ECSBenchmark

const POSITION_ID: int = 1
const HEALTH_ID: int = 2

var _ecs: ECSManager
var _iterations: int = 10000

func _init(ecs: ECSManager, iterations: int = 10000) -> void:
	_ecs = ecs
	_iterations = iterations

func _time_block(name: String, block: Callable) -> float:
	var start: int = Time.get_ticks_usec()
	block.call()
	var end: int = Time.get_ticks_usec()
	return (end - start) / 1_000_000.0

func benchmark_create_entity() -> float:
	_ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	return _time_block("create_entity x %d" % _iterations, func():
		for i in range(_iterations):
			var eid: int = _ecs.create_entity(POSITION_ID)
	)

func benchmark_destroy_entity() -> float:
	_ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	var ids: PackedInt64Array = PackedInt64Array()
	for i in range(_iterations):
		ids.append(_ecs.create_entity(POSITION_ID))
	return _time_block("destroy_entity x %d" % _iterations, func():
		for eid in ids:
			_ecs.destroy_entity(eid)
	)

func benchmark_create_entities_batch() -> float:
	_ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	var batches: int = maxi(1, _iterations / 100)
	var total: int = batches * 100
	return _time_block("create_entities(100) x %d = %d entities" % [batches, total], func():
		for i in range(batches):
			var tmp = _ecs.create_entities(100, POSITION_ID)
	)

func benchmark_destroy_entities_batch() -> float:
	_ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	var batch_size: int = 100
	var batches: int = maxi(1, _iterations / 100)
	var all_ids: PackedInt64Array = PackedInt64Array()
	for i in range(batches):
		var ids: PackedInt64Array = _ecs.create_entities(batch_size, POSITION_ID)
		for eid in ids:
			all_ids.append(eid)
	return _time_block("destroy_entities batch (total %d)" % all_ids.size(), func():
		_ecs.destroy_entities(all_ids)
	)

func benchmark_query_get_entity_ids() -> float:
	_ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	_ecs.register_component(HEALTH_ID, TYPE_PACKED_INT32_ARRAY)
	for i in range(_iterations):
		_ecs.create_entity(POSITION_ID, HEALTH_ID)
	var query: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).with_component(HEALTH_ID).build(_ecs)
	var runs: int = 100
	return _time_block("query.get_entity_ids() x %d (world size %d)" % [runs, _iterations], func():
		for j in range(runs):
			var tmp = query.get_entity_ids()
		)

## Итерация по чанкам на главном потоке: get_chunks() и обход по каждому чанку (подсчёт сущностей).
func benchmark_query_iterate_chunks() -> float:
	_ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	_ecs.register_component(HEALTH_ID, TYPE_PACKED_INT32_ARRAY)
	for i in range(_iterations):
		_ecs.create_entity(POSITION_ID, HEALTH_ID)
	var query: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).with_component(HEALTH_ID).build(_ecs)
	var runs: int = 100
	return _time_block("query.get_chunks() iterate x %d (world size %d)" % [runs, _iterations], func():
		for j in range(runs):
			var total: int = 0
			var chunks: Array[ECSQueryChunk] = query.get_chunks()
			for chunk in chunks:
				total += chunk.get_entity_count()
		)

## Обработка чанков через WorkerThreadPool: в каждом прогоне get_chunks() + group task по индексам (сравнимо с get_entity_ids / iterate_chunks).
func benchmark_query_worker_pool() -> float:
	_ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	_ecs.register_component(HEALTH_ID, TYPE_PACKED_INT32_ARRAY)
	for i in range(_iterations):
		_ecs.create_entity(POSITION_ID, HEALTH_ID)
	var query: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).with_component(HEALTH_ID).build(_ecs)
	var runs: int = 100
	return _time_block("query get_chunks()+WorkerThreadPool x %d (world %d)" % [runs, _iterations], func():
		for _run in range(runs):
			var chunks: Array[ECSQueryChunk] = query.get_chunks()
			if chunks.is_empty():
				continue
			var results: PackedInt32Array = PackedInt32Array()
			results.resize(chunks.size())
			var group_id: int = WorkerThreadPool.add_group_task(_process_chunk_index.bind(chunks, results), chunks.size())
			WorkerThreadPool.wait_for_group_task_completion(group_id)
		)

static func _process_chunk_index(chunks: Array[ECSQueryChunk], results: PackedInt32Array, index: int) -> void:
	var chunk: ECSQueryChunk = chunks[index]
	results[index] = chunk.get_entity_count()

func benchmark_add_remove_component() -> float:
	_ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	_ecs.register_component(HEALTH_ID, TYPE_PACKED_INT32_ARRAY)
	var eid: int = _ecs.create_entity(POSITION_ID)
	var runs: int = min(_iterations, 5000)
	return _time_block("add_component + remove_component x %d" % runs, func():
		for i in range(runs):
			_ecs.add_component(eid, HEALTH_ID)
			_ecs.remove_component(eid, HEALTH_ID)
	)

func benchmark_command_buffer_execute() -> float:
	_ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	var buf: ECSCommandBuffer = ECSCommandBuffer.new(_ecs)
	var cids: PackedInt64Array = PackedInt64Array([POSITION_ID])
	var batch: int = 1000
	for i in range(batch):
		buf.create_entity(cids)
	return _time_block("command_buffer execute (%d create_entity)" % batch, func():
		buf.execute()
	)

func run_all() -> void:
	print("--- ECS Performance (iterations=%d) ---" % _iterations)
	var ecs_fresh: ECSManager = ECSManager.new()
	ecs_fresh.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	var t: float = ECSBenchmark.new(ecs_fresh, _iterations).benchmark_create_entity()
	print("  create_entity: %.3f s" % t)

	ecs_fresh = ECSManager.new()
	t = ECSBenchmark.new(ecs_fresh, _iterations).benchmark_destroy_entity()
	print("  destroy_entity: %.3f s" % t)

	ecs_fresh = ECSManager.new()
	t = ECSBenchmark.new(ecs_fresh, _iterations).benchmark_create_entities_batch()
	print("  create_entities batch: %.3f s" % t)

	ecs_fresh = ECSManager.new()
	t = ECSBenchmark.new(ecs_fresh, _iterations).benchmark_destroy_entities_batch()
	print("  destroy_entities batch: %.3f s" % t)

	ecs_fresh = ECSManager.new()
	t = ECSBenchmark.new(ecs_fresh, _iterations).benchmark_query_get_entity_ids()
	print("  query.get_entity_ids: %.3f s" % t)

	ecs_fresh = ECSManager.new()
	t = ECSBenchmark.new(ecs_fresh, _iterations).benchmark_query_iterate_chunks()
	print("  query.get_chunks() iterate: %.3f s" % t)

	ecs_fresh = ECSManager.new()
	t = ECSBenchmark.new(ecs_fresh, _iterations).benchmark_query_worker_pool()
	print("  query chunks WorkerThreadPool: %.3f s" % t)

	ecs_fresh = ECSManager.new()
	t = ECSBenchmark.new(ecs_fresh, _iterations).benchmark_add_remove_component()
	print("  add/remove_component: %.3f s" % t)

	ecs_fresh = ECSManager.new()
	t = ECSBenchmark.new(ecs_fresh, _iterations).benchmark_command_buffer_execute()
	print("  command_buffer execute: %.3f s" % t)
