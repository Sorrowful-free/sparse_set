@tool
extends EditorScript
class_name RunUnitTests

func _run() -> void:
	var runner: ECSTestRunner = ECSTestRunner.new()
	ECSUnitTestSuites.run_all(runner)
