extends Node

const _Bootstrap := preload("res://addons/gecs/tests/gecs_perf_bootstrap.gd")
const _PgdecsBenchmark := preload("res://addons/pgdecs/ecs/tests/performance/ecs_benchmark.gd")
const _PgdecsManager := preload("res://addons/pgdecs/ecs/ecs_manager.gd")
const _GecsBenchmark := preload("res://addons/gecs/tests/performance/gecs_benchmark.gd")
const _CompareSummary := preload("res://addons/gecs/tests/compare_frameworks_summary.gd")

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var holder: Node = _Bootstrap.prepare(get_tree())
	var iterations: int = 25000
	print("=== Framework comparison (iterations=%d) ===" % iterations)
	print("")
	var pgdecs: Dictionary = _PgdecsBenchmark.new(_PgdecsManager.new(), iterations).run_all()
	print("")
	var gecs: Dictionary = _GecsBenchmark.new(holder, iterations).run_all()
	_CompareSummary.print_summary(pgdecs, gecs, iterations)
	print("")
	print("--- Done ---")
	get_tree().quit()
