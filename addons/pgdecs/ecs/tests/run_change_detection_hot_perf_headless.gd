extends SceneTree

func _initialize() -> void:
	ECSBenchmark.new(ECSManager.new(), 25000).run_change_detection_hot()
	quit(0)
