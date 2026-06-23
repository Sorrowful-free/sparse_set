extends SceneTree

## Quality gate для Composer handoff: unit всегда; perf при PGDECS_RUN_PERF=1.
const _TestRunner = preload("res://addons/pgdecs/ecs/tests/test_runner.gd")
const _UnitTestSuites = preload("res://addons/pgdecs/ecs/tests/ecs_unit_test_suites.gd")

func _initialize() -> void:
	print("=== Composer Quality Gates ===")
	var runner: ECSTestRunner = _TestRunner.new()
	_UnitTestSuites.run_all(runner)
	var failed: int = runner.get_failed()
	if failed != 0:
		push_error("Unit gate FAILED (%d failures)" % failed)
		quit(1)
		return
	print("Unit gate: OK")
	var run_perf: bool = OS.get_environment("PGDECS_RUN_PERF") == "1"
	if run_perf:
		print("Perf gate: running (PGDECS_RUN_PERF=1)...")
		var scales: Array[int] = [5000]
		var manager_script = preload("res://addons/pgdecs/ecs/ecs_manager.gd")
		for iterations in scales:
			ECSBenchmark.new(manager_script.new(), iterations).run_all()
		print("Perf gate: OK (smoke run iterations=%d)" % scales[0])
	else:
		print("Perf gate: SKIPPED (set PGDECS_RUN_PERF=1 to enable)")
	print("=== All gates passed ===")
	quit(0)
