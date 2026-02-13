@tool
extends EditorScript
class_name RunUnitTests

func _run() -> void:
	var runner: ECSTestRunner = ECSTestRunner.new()
	var suites: Array[RefCounted] = [
		ECSEntityIdsUtilsTest.new(),
		ECSEntityIdsPoolTest.new(),
		ECSArchetypeTest.new(),
		ECSManagerTest.new(),
		ECSQueryTest.new(),
		ECSCommandBufferTest.new(),
		SystemRunnerTest.new()
	]
	var names: PackedStringArray = PackedStringArray([
		"EntityIdsUtils", "EntityIdsPool", "Archetype", "ECSManager", "Query", "CommandBuffer", "SystemRunner"
	])
	print("--- ECS Unit Tests ---")
	for i in range(suites.size()):
		print("Suite: %s" % names[i])
		runner.run_suite(names[i], suites[i])
	print("--- Summary ---")
	runner.print_summary()
