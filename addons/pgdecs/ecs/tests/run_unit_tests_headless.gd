extends SceneTree

const _TestRunner = preload("res://addons/pgdecs/ecs/tests/test_runner.gd")
const _UnitTestSuites = preload("res://addons/pgdecs/ecs/tests/ecs_unit_test_suites.gd")

func _initialize() -> void:
	var runner: ECSTestRunner = _TestRunner.new()
	_UnitTestSuites.run_all(runner)
	quit(0 if runner.get_failed() == 0 else 1)
