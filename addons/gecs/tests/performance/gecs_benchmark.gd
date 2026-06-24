extends RefCounted
class_name GECSBenchmark

const BenchPosition := preload("res://addons/gecs/tests/performance/bench_components/bench_position.gd")
const BenchHealth := preload("res://addons/gecs/tests/performance/bench_components/bench_health.gd")
const World := preload("res://addons/gecs/ecs/world.gd")
const Entity := preload("res://addons/gecs/ecs/entity.gd")
const CommandBuffer := preload("res://addons/gecs/ecs/command_buffer.gd")
const Archetype := preload("res://addons/gecs/ecs/archetype.gd")
const _HeavyReadSystem := preload("res://addons/gecs/tests/performance/gecs_benchmark_heavy_read_system.gd")

var _root: Node
var _iterations: int = 10000

func _init(root: Node, iterations: int = 10000) -> void:
	_root = root
	_iterations = iterations

func _time_block(_name: String, block: Callable) -> float:
	var start: int = Time.get_ticks_usec()
	block.call()
	var end: int = Time.get_ticks_usec()
	return (end - start) / 1_000_000.0

func _make_world() -> World:
	var world: World = World.new()
	_root.add_child(world)
	return world

func _dispose_world(world: World) -> void:
	if is_instance_valid(world):
		world.purge(false)
		world.free()

func _spawn_entity(world: World, components: Array) -> Entity:
	var entity: Entity = Entity.new()
	world.add_entity(entity, components, false)
	return entity

func _position_only() -> Array:
	return [BenchPosition.new()]

func _position_and_health() -> Array:
	return [BenchPosition.new(), BenchHealth.new()]

func benchmark_create_entity() -> float:
	var world: World = _make_world()
	var t: float = _time_block("create_entity x %d" % _iterations, func():
		for i in range(_iterations):
			_spawn_entity(world, _position_only())
	)
	_dispose_world(world)
	return t

func benchmark_destroy_entity() -> float:
	var world: World = _make_world()
	var entities: Array[Entity] = []
	for i in range(_iterations):
		entities.append(_spawn_entity(world, _position_only()))
	var t: float = _time_block("destroy_entity x %d" % _iterations, func():
		for entity in entities:
			world.remove_entity(entity)
	)
	_dispose_world(world)
	return t

func benchmark_create_entities_batch() -> float:
	var world: World = _make_world()
	var batches: int = maxi(1, _iterations / 100)
	var total: int = batches * 100
	var t: float = _time_block("create_entities(100) x %d = %d entities" % [batches, total], func():
		for i in range(batches):
			var batch: Array = []
			batch.resize(100)
			for j in range(100):
				batch[j] = Entity.new()
			world.add_entities(batch, _position_only())
	)
	_dispose_world(world)
	return t

func benchmark_destroy_entities_batch() -> float:
	var world: World = _make_world()
	var batch_size: int = 100
	var batches: int = maxi(1, _iterations / 100)
	var all_entities: Array[Entity] = []
	for i in range(batches):
		var batch: Array = []
		batch.resize(batch_size)
		for j in range(batch_size):
			batch[j] = Entity.new()
		world.add_entities(batch, _position_only())
		for entity in batch:
			all_entities.append(entity)
	var t: float = _time_block("destroy_entities batch (total %d)" % all_entities.size(), func():
		world.remove_entities(all_entities)
	)
	_dispose_world(world)
	return t

func benchmark_query_get_entity_ids() -> float:
	var world: World = _make_world()
	for i in range(_iterations):
		_spawn_entity(world, _position_and_health())
	var query = world.query.with_all([BenchPosition, BenchHealth])
	var runs: int = 100
	var t: float = _time_block("query.get_entity_ids() x %d (world size %d)" % [runs, _iterations], func():
		for j in range(runs):
			var tmp = query.execute()
	)
	_dispose_world(world)
	return t

func benchmark_query_iterate_archetypes() -> float:
	var world: World = _make_world()
	for i in range(_iterations):
		_spawn_entity(world, _position_and_health())
	var query = world.query.with_all([BenchPosition, BenchHealth])
	var runs: int = 100
	var t: float = _time_block("query.for_each_chunk iterate x %d (world size %d)" % [runs, _iterations], func():
		for j in range(runs):
			var total: int = 0
			for archetype in query.archetypes():
				total += archetype.entities.size()
	)
	_dispose_world(world)
	return t

func benchmark_query_iterate_entities_with_components() -> float:
	var world: World = _make_world()
	for i in range(_iterations):
		_spawn_entity(world, _position_and_health())
	var query = world.query.with_all([BenchPosition, BenchHealth])
	var pos_path: String = BenchPosition.resource_path
	var health_path: String = BenchHealth.resource_path
	var runs: int = 100
	var t: float = _time_block(
		"query iterate entities+components (chunks) x %d (world size %d)" % [runs, _iterations],
		func():
			for j in range(runs):
				var acc: float = 0.0
				for archetype in query.archetypes():
					var positions: Array = archetype.get_column(pos_path)
					var healths: Array = archetype.get_column(health_path)
					for i in range(archetype.entities.size()):
						var pos = positions[i]
						var health = healths[i]
						if pos == null || health == null:
							continue
						acc += pos.position.x + pos.position.y + float(health.amount)
	)
	_dispose_world(world)
	return t

static func _process_archetype_entities_with_components(
	archetypes: Array,
	results: PackedFloat32Array,
	pos_path: String,
	health_path: String,
	index: int
) -> void:
	var archetype: Archetype = archetypes[index]
	var positions: Array = archetype.get_column(pos_path)
	var healths: Array = archetype.get_column(health_path)
	var acc: float = 0.0
	for i in range(archetype.entities.size()):
		var pos = positions[i]
		var health = healths[i]
		if pos == null || health == null:
			continue
		acc += pos.position.x + pos.position.y + float(health.amount)
	results[index] = acc

func benchmark_query_iterate_entities_with_components_worker_pool() -> float:
	var world: World = _make_world()
	for i in range(_iterations):
		_spawn_entity(world, _position_and_health())
	var query = world.query.with_all([BenchPosition, BenchHealth])
	var pos_path: String = BenchPosition.resource_path
	var health_path: String = BenchHealth.resource_path
	var runs: int = 100
	var t: float = _time_block(
		"query iterate entities+components WorkerThreadPool x %d (world size %d)" % [runs, _iterations],
		func():
			for _run in range(runs):
				var archetypes: Array = query.archetypes()
				if archetypes.is_empty():
					continue
				var results: PackedFloat32Array = PackedFloat32Array()
				results.resize(archetypes.size())
				var group_id: int = WorkerThreadPool.add_group_task(
					_process_archetype_entities_with_components.bind(
						archetypes, results, pos_path, health_path
					),
					archetypes.size()
				)
				WorkerThreadPool.wait_for_group_task_completion(group_id)
				var acc: float = 0.0
				for k in range(results.size()):
					acc += results[k]
	)
	_dispose_world(world)
	return t

static func _process_archetype_index(archetypes: Array, results: PackedInt32Array, index: int) -> void:
	var archetype: Archetype = archetypes[index]
	results[index] = archetype.entities.size()

func benchmark_query_worker_pool() -> float:
	var world: World = _make_world()
	for i in range(_iterations):
		_spawn_entity(world, _position_and_health())
	var query = world.query.with_all([BenchPosition, BenchHealth])
	var runs: int = 100
	var t: float = _time_block("query.for_each_chunk WorkerThreadPool x %d (world %d)" % [runs, _iterations], func():
		for _run in range(runs):
			var archetypes: Array = query.archetypes()
			if archetypes.is_empty():
				continue
			var results: PackedInt32Array = PackedInt32Array()
			results.resize(archetypes.size())
			var group_id: int = WorkerThreadPool.add_group_task(
				_process_archetype_index.bind(archetypes, results),
				archetypes.size()
			)
			WorkerThreadPool.wait_for_group_task_completion(group_id)
	)
	_dispose_world(world)
	return t

func benchmark_add_remove_component() -> float:
	var world: World = _make_world()
	var entity: Entity = _spawn_entity(world, _position_only())
	var runs: int = mini(_iterations, 5000)
	var t: float = _time_block("add_component + remove_component x %d" % runs, func():
		for i in range(runs):
			entity.add_component(BenchHealth.new())
			entity.remove_component(BenchHealth)
	)
	_dispose_world(world)
	return t

func benchmark_command_buffer_execute() -> float:
	var world: World = _make_world()
	var buf: CommandBuffer = CommandBuffer.new(world)
	var batch: int = 1000
	for i in range(batch):
		buf.add_entity(Entity.new())
	var t: float = _time_block("command_buffer execute (%d create_entity)" % batch, func():
		buf.execute()
	)
	_dispose_world(world)
	return t

func benchmark_command_buffer_coalescing_frame() -> float:
	var world: World = _make_world()
	var cycles: int = maxi(1, _iterations / 25)
	var survivors: Array[Entity] = []
	survivors.resize(cycles)
	for i in range(cycles):
		survivors[i] = _spawn_entity(world, _position_only())
	var buf: CommandBuffer = CommandBuffer.new(world)
	for i in range(cycles):
		var temp: Entity = Entity.new()
		buf.add_entity(temp)
		buf.remove_entity(temp)
		var survivor: Entity = survivors[i]
		buf.add_component(survivor, BenchHealth.new())
		buf.remove_component(survivor, BenchHealth)
	for i in range(cycles):
		buf.remove_entity(survivors[i])
	var raw_cmds: int = cycles * 5
	var t: float = _time_block(
		"command_buffer coalescing frame (%d cycles, %d raw cmds)" % [cycles, raw_cmds],
		func():
			buf.execute()
	)
	_dispose_world(world)
	return t

func _attach_system(world: World, system: Node) -> Node:
	system._world = world
	world.add_child(system)
	system._internal_setup()
	return system

func benchmark_system_process_steady() -> float:
	var world: World = _make_world()
	for i in range(_iterations):
		_spawn_entity(world, _position_and_health())
	var system: _HeavyReadSystem = _attach_system(world, _HeavyReadSystem.new())
	system._handle(0.016)
	var runs: int = 100
	var t: float = _time_block("system change_detection steady (no writes) x %d (world %d)" % [runs, _iterations], func():
		for j in range(runs):
			system._handle(0.016)
	)
	_dispose_world(world)
	return t

func benchmark_system_process_scattered() -> float:
	var world: World = _make_world()
	var entities: Array[Entity] = []
	entities.resize(_iterations)
	for i in range(_iterations):
		entities[i] = _spawn_entity(world, _position_and_health())
	var system: _HeavyReadSystem = _attach_system(world, _HeavyReadSystem.new())
	var touches_per_frame: int = maxi(1, _iterations / 50)
	var runs: int = 100
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 12345
	var t: float = _time_block(
		"system process scattered (~%d rand writes/frame) x %d" % [touches_per_frame, runs],
		func():
			system._handle(0.016)
			for j in range(runs):
				for k in range(touches_per_frame):
					var entity: Entity = entities[rng.randi() % entities.size()]
					var pos = entity.get_component(BenchPosition)
					if pos:
						pos.position = Vector2(float(j + k), float(k))
				system._handle(0.016)
	)
	_dispose_world(world)
	return t

func benchmark_system_process_hot_chunks() -> float:
	var world: World = _make_world()
	var entities: Array[Entity] = []
	entities.resize(_iterations)
	for i in range(_iterations):
		entities[i] = _spawn_entity(world, _position_and_health())
	var system: _HeavyReadSystem = _attach_system(world, _HeavyReadSystem.new())
	var chunk_size: int = 64
	var chunk_count: int = maxi(1, (entities.size() + chunk_size - 1) / chunk_size)
	var hot_chunks_per_frame: int = 2
	var touches_per_hot_chunk: int = 32
	var runs: int = 100
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 54321
	var t: float = _time_block(
		"system process hot-chunks (%d chunks x %d writes/frame) x %d (world %d)" % [
			hot_chunks_per_frame, touches_per_hot_chunk, runs, _iterations],
		func():
			system._handle(0.016)
			for j in range(runs):
				for h in range(hot_chunks_per_frame):
					var ci: int = rng.randi() % chunk_count
					var base: int = ci * chunk_size
					var in_chunk: int = mini(chunk_size, entities.size() - base)
					if in_chunk <= 0:
						continue
					for k in range(touches_per_hot_chunk):
						var entity: Entity = entities[base + rng.randi() % in_chunk]
						var pos = entity.get_component(BenchPosition)
						if pos:
							pos.position = Vector2(float(j + h + k), float(k))
				system._handle(0.016)
	)
	_dispose_world(world)
	return t

func run_all() -> void:
	print("--- GECS Performance (iterations=%d) ---" % _iterations)

	var t: float = GECSBenchmark.new(_root, _iterations).benchmark_create_entity()
	print("  create_entity: %.3f s" % t)

	t = GECSBenchmark.new(_root, _iterations).benchmark_destroy_entity()
	print("  destroy_entity: %.3f s" % t)

	t = GECSBenchmark.new(_root, _iterations).benchmark_create_entities_batch()
	print("  create_entities batch: %.3f s" % t)

	t = GECSBenchmark.new(_root, _iterations).benchmark_destroy_entities_batch()
	print("  destroy_entities batch: %.3f s" % t)

	t = GECSBenchmark.new(_root, _iterations).benchmark_query_get_entity_ids()
	print("  query.get_entity_ids: %.3f s" % t)

	t = GECSBenchmark.new(_root, _iterations).benchmark_query_iterate_archetypes()
	print("  query.for_each_chunk iterate: %.3f s" % t)

	t = GECSBenchmark.new(_root, _iterations).benchmark_query_iterate_entities_with_components()
	print("  query iterate entities+components: %.3f s" % t)

	t = GECSBenchmark.new(_root, _iterations).benchmark_query_iterate_entities_with_components_worker_pool()
	print("  query iterate entities+components WorkerThreadPool: %.3f s" % t)

	t = GECSBenchmark.new(_root, _iterations).benchmark_query_worker_pool()
	print("  query.for_each_chunk WorkerThreadPool: %.3f s" % t)

	t = GECSBenchmark.new(_root, _iterations).benchmark_add_remove_component()
	print("  add/remove_component: %.3f s" % t)

	t = GECSBenchmark.new(_root, _iterations).benchmark_command_buffer_execute()
	print("  command_buffer execute: %.3f s" % t)

	t = GECSBenchmark.new(_root, _iterations).benchmark_command_buffer_coalescing_frame()
	print("  command_buffer coalescing frame: %.3f s" % t)

	t = GECSBenchmark.new(_root, _iterations).benchmark_system_process_steady()
	print("  system change_detection steady: %.3f s" % t)

	t = GECSBenchmark.new(_root, _iterations).benchmark_system_process_scattered()
	print("  system process scattered: %.3f s" % t)

	t = GECSBenchmark.new(_root, _iterations).benchmark_system_process_hot_chunks()
	print("  system process hot-chunks: %.3f s" % t)
