extends SceneTree

const _BenchmarkScript = preload("res://addons/pgdecs/ecs/tests/performance/ecs_benchmark.gd")
const _ManagerScript = preload("res://addons/pgdecs/ecs/ecs_manager.gd")

func _initialize() -> void:
	var benchmark: ECSBenchmark = _BenchmarkScript.new(_ManagerScript.new(), 25000)
	benchmark.run_change_detection_hot()
	quit(0)
