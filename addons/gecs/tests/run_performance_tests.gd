@tool
extends EditorScript
class_name RunGECSPerformanceTests

const _Bootstrap := preload("res://addons/gecs/tests/gecs_perf_bootstrap.gd")
const _BenchmarkScript = preload("res://addons/gecs/tests/performance/gecs_benchmark.gd")

func _run() -> void:
	var tree: SceneTree = get_editor_interface().get_base_control().get_tree()
	var holder: Node = _Bootstrap.prepare(tree)
	var scales: Array = [5000, 15000, 25000]
	for i in range(scales.size()):
		var iterations: int = scales[i]
		if i > 0:
			print("")
		_BenchmarkScript.new(holder, iterations).run_all()
	print("")
	print("--- Done ---")
