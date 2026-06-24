extends Node

const _Bootstrap := preload("res://addons/gecs/tests/gecs_perf_bootstrap.gd")
const _Benchmark := preload("res://addons/gecs/tests/performance/gecs_benchmark.gd")

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var holder: Node = _Bootstrap.prepare(get_tree())
	_Benchmark.new(holder, 25000).run_all()
	print("")
	print("--- Done ---")
	get_tree().quit()
