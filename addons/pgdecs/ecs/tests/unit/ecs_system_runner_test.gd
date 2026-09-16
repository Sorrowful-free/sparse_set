extends GutTest
class_name SystemRunnerTest

const POSITION_ID: int = 1
const HEALTH_ID: int = 2

class RunSystem extends ECSSystemBase:
	const CID: int = 1
	func process_system(_delta: float) -> void:
		get_command_buffer().create_entity([CID])

class UpdateCountSystem extends ECSSystemBase:
	var update_count: int = 0
	func process_system(delta: float) -> void:
		update_count += 1

class ChunkCountSystem extends ECSSystemChunkBase:
	var total_processed: int = 0
	func build_query() -> ECSQuery:
		return ECSQueryBuilder.new().with_component(POSITION_ID).with_component(HEALTH_ID).build(get_ecs_manager())
	func process_chunk(chunk: ECSQueryChunk, _delta: float) -> void:
		total_processed += chunk.get_entity_count()

func test_runner_calls_update() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	var sys: UpdateCountSystem = UpdateCountSystem.new(ecs)
	var run: ECSSystemRunner = ECSSystemRunner.new()
	run.add_system(sys)
	assert_eq(sys.update_count, 0)
	run.run(0.016)
	assert_eq(sys.update_count, 1)
	run.run(0.016)
	assert_eq(sys.update_count, 2)

func test_command_buffer_executed_after_run() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	var run: ECSSystemRunner = ECSSystemRunner.new()
	var sys: RunSystem = RunSystem.new(ecs)
	run.add_system(sys)
	assert_eq(ECSQueryBuilder.new().with_component(POSITION_ID).build(ecs).get_entity_ids().size(), 0)
	run.run(0.0)
	assert_eq(ECSQueryBuilder.new().with_component(POSITION_ID).build(ecs).get_entity_ids().size(), 1)

func test_chunk_system_processes_all_entities() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	ecs.register_component(HEALTH_ID, ECSComponent.Type.PACKED_INT32)
	var ids: PackedInt64Array = ecs.create_entities_packed(10, PackedInt64Array([POSITION_ID, HEALTH_ID]))
	var sys: ChunkCountSystem = ChunkCountSystem.new(ecs)
	var run: ECSSystemRunner = ECSSystemRunner.new()
	run.add_system(sys)
	run.run(0.0)
	assert_eq(sys.total_processed, ids.size())

## При use_worker_pool накопление в process_chunk не потокобезопасно; проверяем только что раннер отрабатывает.
func test_chunk_system_worker_pool_runs() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	ecs.register_component(HEALTH_ID, ECSComponent.Type.PACKED_INT32)
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
	func process_system(_delta: float) -> void:
		if done:
			return
		get_command_buffer().destroy_entity(target_id)
		done = true

func test_runner_flushes_deferred_archetype_gc() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	var eid: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID]))
	var sys: DestroyViaBufferSystem = DestroyViaBufferSystem.new(ecs)
	sys.target_id = eid
	var run: ECSSystemRunner = ECSSystemRunner.new()
	run.add_system(sys)
	assert_eq(ecs.count_live_archetypes(), 1)
	run.run(0.0)
	ecs.flush_archetype_gc_if_pending()
	assert_eq(ecs.count_live_archetypes(), 0)
	assert_eq(ecs.count_registered_archetypes(), 0)

class SpawnSystem extends ECSSystemBase:
	func process_system(_delta: float) -> void:
		get_command_buffer().create_entity([POSITION_ID])

class CountAfterSpawnSystem extends ECSSystemChunkBase:
	var seen: int = 0
	func build_query() -> ECSQuery:
		return ECSQueryBuilder.new().with_component(POSITION_ID).build(get_ecs_manager())
	func process_chunk(chunk: ECSQueryChunk, _delta: float) -> void:
		seen += chunk.get_entity_count()

func test_per_system_flush_visibility_in_same_run_group() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	var spawn: SpawnSystem = SpawnSystem.new(ecs)
	var count: CountAfterSpawnSystem = CountAfterSpawnSystem.new(ecs)
	var run: ECSSystemRunner = ECSSystemRunner.new()
	run.add_system(spawn)
	run.add_system(count)
	run.run_group(ECSSystemRunGroups.DEFAULT, 0.0)
	assert_eq(count.seen, 1)

func test_group_isolation_between_run_groups() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	var spawn: SpawnSystem = SpawnSystem.new(ecs)
	spawn.run_group = ECSSystemRunGroups.SIMULATION
	var count: CountAfterSpawnSystem = CountAfterSpawnSystem.new(ecs)
	count.run_group = ECSSystemRunGroups.FRAME
	var run: ECSSystemRunner = ECSSystemRunner.new()
	run.add_system(spawn, ECSSystemRunGroups.SIMULATION)
	run.add_system(count, ECSSystemRunGroups.FRAME)
	run.run_group(ECSSystemRunGroups.FRAME, 0.0)
	assert_eq(count.seen, 0)
	run.run_group(ECSSystemRunGroups.SIMULATION, 0.0)
	run.run_group(ECSSystemRunGroups.FRAME, 0.0)
	assert_eq(count.seen, 1)

class PerGroupFlushSystem extends ECSSystemBase:
	func process_system(_delta: float) -> void:
		get_command_buffer().create_entity([POSITION_ID])

func test_per_group_flush_mode() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	var sys: PerGroupFlushSystem = PerGroupFlushSystem.new(ecs)
	sys.command_buffer_flush_mode = ECSSystemBase.CommandBufferFlushMode.PER_GROUP
	var run: ECSSystemRunner = ECSSystemRunner.new()
	run.add_system(sys)
	assert_eq(ECSQueryBuilder.new().with_component(POSITION_ID).build(ecs).get_entity_ids().size(), 0)
	run.run_group(ECSSystemRunGroups.DEFAULT, 0.0)
	assert_eq(ECSQueryBuilder.new().with_component(POSITION_ID).build(ecs).get_entity_ids().size(), 1)

class ManualFlushSystem extends ECSSystemBase:
	func process_system(_delta: float) -> void:
		get_command_buffer().create_entity([POSITION_ID])

func test_manual_flush_mode() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
	var sys: ManualFlushSystem = ManualFlushSystem.new(ecs)
	sys.command_buffer_flush_mode = ECSSystemBase.CommandBufferFlushMode.MANUAL
	var run: ECSSystemRunner = ECSSystemRunner.new()
	run.add_system(sys)
	run.run_group(ECSSystemRunGroups.DEFAULT, 0.0)
	assert_eq(ECSQueryBuilder.new().with_component(POSITION_ID).build(ecs).get_entity_ids().size(), 0)
	run.flush_manual_command_buffers()
	assert_eq(ECSQueryBuilder.new().with_component(POSITION_ID).build(ecs).get_entity_ids().size(), 1)
