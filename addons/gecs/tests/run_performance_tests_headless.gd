extends Node

const _Bootstrap := preload("res://addons/gecs/tests/gecs_perf_bootstrap.gd")
const _BenchmarkScript = preload("res://addons/gecs/tests/performance/gecs_benchmark.gd")

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var holder: Node = _Bootstrap.prepare(get_tree())
	var scales: Array[int] = [5000, 15000, 25000]
	for i in range(scales.size()):
		var iterations: int = scales[i]
		if i > 0:
			print("")
		_BenchmarkScript.new(holder, iterations).run_all()
	print("")
	print("--- Done ---")
	get_tree().quit()
