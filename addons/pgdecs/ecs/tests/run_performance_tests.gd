@tool
extends EditorScript
class_name RunPerformanceTests

func _run() -> void:
	var scales: Array = [5000, 15000, 25000]
	for i in range(scales.size()):
		var iterations: int = scales[i]
		if i > 0:
			print("")
		ECSBenchmark.new(ECSManager.new(), iterations).run_all()
	print("")
	print("--- Done ---")
