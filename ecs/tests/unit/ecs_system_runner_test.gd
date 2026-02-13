extends RefCounted
class_name SystemRunnerTest

const POSITION_ID: int = 1

class RunSystem extends ECSSystemBase:
	const CID: int = 1
	func update(_delta: float) -> void:
		get_command_buffer().create_entity(PackedInt64Array([CID]))

class TestSystem extends ECSSystemBase:
	var update_count: int = 0
	func update(delta: float) -> void:
		update_count += 1

func test_runner_calls_update(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	var sys: TestSystem = TestSystem.new(ecs)
	var run: ECSSystemRunner = ECSSystemRunner.new()
	run.add_system(sys)
	runner.assert_eq(sys.update_count, 0)
	run.run(0.016)
	runner.assert_eq(sys.update_count, 1)
	run.run(0.016)
	runner.assert_eq(sys.update_count, 2)

func test_command_buffer_executed_after_run(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	var run: ECSSystemRunner = ECSSystemRunner.new()
	var sys: RunSystem = RunSystem.new(ecs)
	run.add_system(sys)
	runner.assert_eq(ECSQueryBuilder.new().with_component(POSITION_ID).build(ecs).get_entity_ids().size(), 0)
	run.run(0.0)
	runner.assert_eq(ECSQueryBuilder.new().with_component(POSITION_ID).build(ecs).get_entity_ids().size(), 1)
