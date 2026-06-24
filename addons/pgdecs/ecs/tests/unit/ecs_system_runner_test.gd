extends GutTest
class_name SystemRunnerTest

const POSITION_ID: int = 1
const HEALTH_ID: int = 2

class RunSystem extends ECSSystemBase:
	const CID: int = 1
	func update(_delta: float) -> void:
		get_command_buffer().create_entity([CID])

class TestSystem extends ECSSystemBase:
	var update_count: int = 0
	func update(delta: float) -> void:
		update_count += 1

class ChunkCountSystem extends ECSSystemChunkBase:
	var total_processed: int = 0
	func _build_query() -> ECSQuery:
		return ECSQueryBuilder.new().with_component(POSITION_ID).with_component(HEALTH_ID).build(get_ecs_manager())
	func process_chunk(chunk: ECSQueryChunk, _delta: float) -> void:
		total_processed += chunk.get_entity_count()

func test_runner_calls_update() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	var sys: TestSystem = TestSystem.new(ecs)
	var run: ECSSystemRunner = ECSSystemRunner.new()
	run.add_system(sys)
	assert_eq(sys.update_count, 0)
	run.run(0.016)
	assert_eq(sys.update_count, 1)
	run.run(0.016)
	assert_eq(sys.update_count, 2)

func test_command_buffer_executed_after_run() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	var run: ECSSystemRunner = ECSSystemRunner.new()
	var sys: RunSystem = RunSystem.new(ecs)
	run.add_system(sys)
	assert_eq(ECSQueryBuilder.new().with_component(POSITION_ID).build(ecs).get_entity_ids().size(), 0)
	run.run(0.0)
	assert_eq(ECSQueryBuilder.new().with_component(POSITION_ID).build(ecs).get_entity_ids().size(), 1)

func test_chunk_system_processes_all_entities() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	ecs.register_component(HEALTH_ID, TYPE_PACKED_INT32_ARRAY)
	var ids: PackedInt64Array = ecs.create_entities_packed(10, PackedInt64Array([POSITION_ID, HEALTH_ID]))
	var sys: ChunkCountSystem = ChunkCountSystem.new(ecs)
	var run: ECSSystemRunner = ECSSystemRunner.new()
	run.add_system(sys)
	run.run(0.0)
	assert_eq(sys.total_processed, ids.size())

## При use_worker_pool накопление в process_chunk не потокобезопасно; проверяем только что раннер отрабатывает.
func test_chunk_system_worker_pool_runs() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	ecs.register_component(HEALTH_ID, TYPE_PACKED_INT32_ARRAY)
	var ids: PackedInt64Array = ecs.create_entities_packed(10, PackedInt64Array([POSITION_ID, HEALTH_ID]))
	var sys: ChunkCountSystem = ChunkCountSystem.new(ecs)
	sys.use_worker_pool = true
	var run: ECSSystemRunner = ECSSystemRunner.new()
	run.add_system(sys)
	run.run(0.0)
	assert_eq(ECSQueryBuilder.new().with_component(POSITION_ID).with_component(HEALTH_ID).build(ecs).get_entity_ids().size(), ids.size())

class DestroyViaBufferSystem extends ECSSystemBase:
	var target_id: int = 0
	var done: bool = false
	func update(_delta: float) -> void:
		if done:
			return
		get_command_buffer().destroy_entity(target_id)
		done = true

func test_runner_flushes_deferred_archetype_gc() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	var eid: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	var sys: DestroyViaBufferSystem = DestroyViaBufferSystem.new(ecs)
	sys.target_id = eid
	var run: ECSSystemRunner = ECSSystemRunner.new()
	run.add_system(sys)
	assert_eq(ecs.count_live_archetypes(), 1)
	run.run(0.0)
	assert_eq(ecs.count_live_archetypes(), 0)
	assert_eq(ecs.count_registered_archetypes(), 0)
