extends SceneTree

const _BenchmarkScript = preload("res://addons/pgdecs/ecs/tests/performance/ecs_benchmark.gd")
const _ManagerScript = preload("res://addons/pgdecs/ecs/ecs_manager.gd")

func _initialize() -> void:
	var scales: Array[int] = [5000, 15000, 25000]
	for i in range(scales.size()):
		var iterations: int = scales[i]
		if i > 0:
			print("")
		var benchmark: ECSBenchmark = _BenchmarkScript.new(_ManagerScript.new(), iterations)
		benchmark.run_all()
	print("")
	print("--- Done ---")
	quit(0)
