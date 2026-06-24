extends Node

const _Bootstrap := preload("res://addons/gecs/tests/gecs_perf_bootstrap.gd")
const _BenchmarkScript = preload("res://addons/gecs/tests/performance/gecs_benchmark.gd")

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var holder: Node = _Bootstrap.prepare(get_tree())
	_BenchmarkScript.new(holder, 500).run_all()
	print("--- Smoke OK ---")
	get_tree().quit()
