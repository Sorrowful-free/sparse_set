extends GutTest
class_name ECSSystemSchedulerTest

const POSITION_ID: int = 1

class TickCountSystem extends ECSSystemBase:
	var tick_count: int = 0
	func update(_delta: float) -> void:
		tick_count += 1

class OrderSystem extends ECSSystemBase:
	var group_name: StringName
	var log: Array[StringName]
	func update(_delta: float) -> void:
		log.append(group_name)

func _make_config(
	group: StringName,
	hook: ECSSystemGroupConfig.ProcessHook,
	hz: float,
	order: int
) -> ECSSystemGroupConfig:
	var config := ECSSystemGroupConfig.new()
	config.group = group
	config.process_hook = hook
	config.hz = hz
	config.execution_order = order
	return config

func test_physics_and_process_hook_routing() -> void:
	var ecs: ECSManager = ECSManager.new()
	var runner := ECSSystemRunner.new()
	var scheduler := ECSSystemScheduler.new()

	var physics_sys := TickCountSystem.new(ecs)
	physics_sys.run_group = &"physics_grp"
	runner.add_system(physics_sys, &"physics_grp")

	var process_sys := TickCountSystem.new(ecs)
	process_sys.run_group = &"process_grp"
	runner.add_system(process_sys, &"process_grp")

	scheduler.install(
		[
			_make_config(&"physics_grp", ECSSystemGroupConfig.ProcessHook.PHYSICS_PROCESS, 0.0, 0),
			_make_config(&"process_grp", ECSSystemGroupConfig.ProcessHook.PROCESS, 0.0, 0),
		],
		runner
	)

	scheduler.tick_physics(0.016)
	assert_eq(physics_sys.tick_count, 1)
	assert_eq(process_sys.tick_count, 0)

	scheduler.tick_process(0.016)
	assert_eq(process_sys.tick_count, 1)

func test_execution_order_within_process_hook() -> void:
	var ecs: ECSManager = ECSManager.new()
	var runner := ECSSystemRunner.new()
	var scheduler := ECSSystemScheduler.new()
	var order_log: Array[StringName] = []

	var first := OrderSystem.new(ecs)
	first.group_name = &"first"
	first.log = order_log
	first.run_group = &"first"
	runner.add_system(first, &"first")

	var second := OrderSystem.new(ecs)
	second.group_name = &"second"
	second.log = order_log
	second.run_group = &"second"
	runner.add_system(second, &"second")

	scheduler.install(
		[
			_make_config(&"second", ECSSystemGroupConfig.ProcessHook.PROCESS, 0.0, 10),
			_make_config(&"first", ECSSystemGroupConfig.ProcessHook.PROCESS, 0.0, 0),
		],
		runner
	)

	scheduler.tick_process(0.0)
	assert_eq(order_log.size(), 2)
	assert_eq(order_log[0], &"first")
	assert_eq(order_log[1], &"second")

func test_hz_accumulator() -> void:
	var ecs: ECSManager = ECSManager.new()
	var runner := ECSSystemRunner.new()
	var scheduler := ECSSystemScheduler.new()
	var sys := TickCountSystem.new(ecs)
	sys.run_group = &"throttled"
	runner.add_system(sys, &"throttled")

	scheduler.install(
		[_make_config(&"throttled", ECSSystemGroupConfig.ProcessHook.PROCESS, 10.0, 0)],
		runner
	)

	scheduler.tick_process(1.0)
	assert_eq(sys.tick_count, 10)

func test_manual_fire_group() -> void:
	var ecs: ECSManager = ECSManager.new()
	var runner := ECSSystemRunner.new()
	var scheduler := ECSSystemScheduler.new()
	var sys := TickCountSystem.new(ecs)
	sys.run_group = &"manual_grp"
	runner.add_system(sys, &"manual_grp")

	scheduler.install(
		[_make_config(&"manual_grp", ECSSystemGroupConfig.ProcessHook.MANUAL, 0.0, 0)],
		runner
	)

	scheduler.tick_process(0.016)
	assert_eq(sys.tick_count, 0)
	scheduler.fire_group(&"manual_grp", 0.016)
	assert_eq(sys.tick_count, 1)

func test_set_group_hz_runtime() -> void:
	var ecs: ECSManager = ECSManager.new()
	var runner := ECSSystemRunner.new()
	var scheduler := ECSSystemScheduler.new()
	var sys := TickCountSystem.new(ecs)
	sys.run_group = &"net"
	runner.add_system(sys, &"net")

	scheduler.install(
		[_make_config(&"net", ECSSystemGroupConfig.ProcessHook.PROCESS, 20.0, 0)],
		runner
	)
	scheduler.set_group_hz(&"net", 10.0)
	for _i in range(3):
		scheduler.tick_process(0.1)
	assert_eq(sys.tick_count, 3)
