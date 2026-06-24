extends SceneTree

func _initialize() -> void:
	var scales: Array[int] = [5000, 15000, 25000]
	for i in range(scales.size()):
		var iterations: int = scales[i]
		if i > 0:
			print("")
		ECSBenchmark.new(ECSManager.new(), iterations).run_all()
	print("")
	print("--- Done ---")
	quit(0)
