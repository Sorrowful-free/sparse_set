extends SceneTree

## Quality gate: GUT unit tests + опциональный perf при PGDECS_RUN_PERF=1.

func _init() -> void:
	var VersionConversion = load("res://addons/gut/version_conversion.gd")
	if VersionConversion.error_if_not_all_classes_imported():
		quit(0)
		return

	load("res://addons/gut/gut_loader.gd")

	var max_iter := 20
	var iter := 0
	while Engine.get_main_loop() == null and iter < max_iter:
		await create_timer(0.01).timeout
		iter += 1

	if Engine.get_main_loop() == null:
		push_error("Main loop did not start in time.")
		quit(1)
		return

	print("=== Composer Quality Gates ===")
	await _run_unit_gate()
	if _unit_failed:
		push_error("Unit gate FAILED (%d failures)" % _unit_failed)
		quit(1)
		return

	print("Unit gate: OK")
	await _run_perf_gate()
	print("=== All gates passed ===")
	quit(0)

var _unit_failed: int = 0

func _run_unit_gate() -> void:
	var GutConfig = load("res://addons/gut/gut_config.gd")
	var GutRunnerScene = load("res://addons/gut/gui/GutRunner.tscn")

	var gut_config = GutConfig.new()
	gut_config.load_options("res://.gutconfig.json")
	gut_config.options.should_exit = false

	var runner = GutRunnerScene.instantiate()
	get_root().add_child(runner)
	runner.set_gut_config(gut_config)

	var done := false
	runner.gut.end_run.connect(func() -> void:
		_unit_failed = runner.gut.get_fail_count()
		done = true
	)
	runner.run_tests(false)

	while not done:
		await process_frame

func _run_perf_gate() -> void:
	var run_perf: bool = OS.get_environment("PGDECS_RUN_PERF") == "1"
	if not run_perf:
		print("Perf gate: SKIPPED (set PGDECS_RUN_PERF=1 to enable)")
		return

	print("Perf gate: running (PGDECS_RUN_PERF=1)...")
	var scales: Array[int] = [5000]
	for iterations in scales:
		ECSBenchmark.new(ECSManager.new(), iterations).run_all()
	print("Perf gate: OK (smoke run iterations=%d)" % scales[0])
