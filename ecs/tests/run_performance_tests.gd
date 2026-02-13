@tool
extends EditorScript
class_name RunPerformanceTests

func _run() -> void:
	var iterations: int = 10_000
	ECSBenchmark.new(ECSManager.new(), iterations).run_all()
