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
			var eid: int = _ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	)

func benchmark_destroy_entity() -> float:
	_ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	var ids: PackedInt64Array = PackedInt64Array()
	for i in range(_iterations):
		ids.append(_ecs.create_entity_packed(PackedInt64Array([POSITION_ID])))
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
			var tmp = _ecs.create_entities_packed(100, PackedInt64Array([POSITION_ID]))
	)

func benchmark_destroy_entities_batch() -> float:
	_ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	var batch_size: int = 100
	var batches: int = maxi(1, _iterations / 100)
	var all_ids: PackedInt64Array = PackedInt64Array()
	for i in range(batches):
		var ids: PackedInt64Array = _ecs.create_entities_packed(batch_size, PackedInt64Array([POSITION_ID]))
		for eid in ids:
			all_ids.append(eid)
	return _time_block("destroy_entities batch (total %d)" % all_ids.size(), func():
		_ecs.destroy_entities(all_ids)
	)

func benchmark_query_get_entity_ids() -> float:
	_ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	_ecs.register_component(HEALTH_ID, TYPE_PACKED_INT32_ARRAY)
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
	_ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	_ecs.register_component(HEALTH_ID, TYPE_PACKED_INT32_ARRAY)
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
	_ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	_ecs.register_component(HEALTH_ID, TYPE_PACKED_INT32_ARRAY)
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

## То же, что iterate_entities_with_components, но чанки обрабатываются через WorkerThreadPool:
## каждый воркер обрабатывает один чанк (читает position и health по слотам), пишет сумму в results[index].
static func _process_chunk_entities_with_components(chunks: Array[ECSQueryChunk], results: PackedFloat32Array, position_id: int, health_id: int, index: int) -> void:
	var chunk: ECSQueryChunk = chunks[index]
	var pos_chunk: ECSComponentBaseArrayChunk = chunk.get_component_chunk(position_id)
	var health_chunk: ECSComponentBaseArrayChunk = chunk.get_component_chunk(health_id)
	if pos_chunk == null || health_chunk == null:
		results[index] = 0.0
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
	results[index] = acc

## Итерация по сущностям с чтением всех компонентов через WorkerThreadPool (аналог iterate_entities_with_components).
func benchmark_query_iterate_entities_with_components_worker_pool() -> float:
	_ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	_ecs.register_component(HEALTH_ID, TYPE_PACKED_INT32_ARRAY)
	for i in range(_iterations):
		_ecs.create_entity_packed(PackedInt64Array([POSITION_ID, HEALTH_ID]))
	var query: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).with_component(HEALTH_ID).build(_ecs)
	var runs: int = 100
	var worker_chunks: Array[ECSQueryChunk] = []
	return _time_block("query iterate entities+components WorkerThreadPool x %d (world size %d)" % [runs, _iterations], func():
		for _run in range(runs):
			query.collect_chunks(worker_chunks)
			if worker_chunks.is_empty():
				continue
			var results: PackedFloat32Array = PackedFloat32Array()
			results.resize(worker_chunks.size())
			var group_id: int = WorkerThreadPool.add_group_task(_process_chunk_entities_with_components.bind(worker_chunks, results, POSITION_ID, HEALTH_ID), worker_chunks.size())
			WorkerThreadPool.wait_for_group_task_completion(group_id)
			var acc: float = 0.0
			for k in range(results.size()):
				acc += results[k]
		)

## Обработка чанков через WorkerThreadPool: collect_chunks (for_each_chunk) + group task по индексам.
func benchmark_query_worker_pool() -> float:
	_ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	_ecs.register_component(HEALTH_ID, TYPE_PACKED_INT32_ARRAY)
	for i in range(_iterations):
		_ecs.create_entity_packed(PackedInt64Array([POSITION_ID, HEALTH_ID]))
	var query: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).with_component(HEALTH_ID).build(_ecs)
	var runs: int = 100
	var worker_chunks: Array[ECSQueryChunk] = []
	return _time_block("query.for_each_chunk WorkerThreadPool x %d (world %d)" % [runs, _iterations], func():
		for _run in range(runs):
			query.collect_chunks(worker_chunks)
			if worker_chunks.is_empty():
				continue
			var results: PackedInt32Array = PackedInt32Array()
			results.resize(worker_chunks.size())
			var group_id: int = WorkerThreadPool.add_group_task(_process_chunk_index.bind(worker_chunks, results), worker_chunks.size())
			WorkerThreadPool.wait_for_group_task_completion(group_id)
		)

static func _process_chunk_index(chunks: Array[ECSQueryChunk], results: PackedInt32Array, index: int) -> void:
	var chunk: ECSQueryChunk = chunks[index]
	results[index] = chunk.get_entity_count()

func benchmark_add_remove_component() -> float:
	_ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	_ecs.register_component(HEALTH_ID, TYPE_PACKED_INT32_ARRAY)
	var eid: int = _ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
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

func benchmark_command_buffer_coalescing_frame() -> float:
	_ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	_ecs.register_component(HEALTH_ID, TYPE_PACKED_INT32_ARRAY)
	var cycles: int = maxi(1, _iterations / 25)
	var pos_only: PackedInt64Array = PackedInt64Array([POSITION_ID])
	var survivors: PackedInt64Array = PackedInt64Array()
	survivors.resize(cycles)
	for i in range(cycles):
		survivors[i] = _ecs.create_entity_packed(pos_only)
	var buf: ECSCommandBuffer = ECSCommandBuffer.new(_ecs)
	for i in range(cycles):
		var temp_id: int = buf.create_entity(pos_only)
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
	)

func run_all() -> void:
	print("--- ECS Performance (iterations=%d) ---" % _iterations)
	var ecs_fresh: ECSManager = ECSManager.new()
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
	print("  query.for_each_chunk iterate: %.3f s" % t)

	ecs_fresh = ECSManager.new()
	t = ECSBenchmark.new(ecs_fresh, _iterations).benchmark_query_iterate_entities_with_components()
	print("  query iterate entities+components: %.3f s" % t)

	ecs_fresh = ECSManager.new()
	t = ECSBenchmark.new(ecs_fresh, _iterations).benchmark_query_iterate_entities_with_components_worker_pool()
	print("  query iterate entities+components WorkerThreadPool: %.3f s" % t)

	ecs_fresh = ECSManager.new()
	t = ECSBenchmark.new(ecs_fresh, _iterations).benchmark_query_worker_pool()
	print("  query.for_each_chunk WorkerThreadPool: %.3f s" % t)

	ecs_fresh = ECSManager.new()
	t = ECSBenchmark.new(ecs_fresh, _iterations).benchmark_add_remove_component()
	print("  add/remove_component: %.3f s" % t)

	ecs_fresh = ECSManager.new()
	t = ECSBenchmark.new(ecs_fresh, _iterations).benchmark_command_buffer_execute()
	print("  command_buffer execute: %.3f s" % t)

	ecs_fresh = ECSManager.new()
	t = ECSBenchmark.new(ecs_fresh, _iterations).benchmark_command_buffer_coalescing_frame()
	print("  command_buffer coalescing frame: %.3f s" % t)
