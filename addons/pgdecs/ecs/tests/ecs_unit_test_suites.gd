extends RefCounted
class_name ECSUnitTestSuites

const _EntityIdsUtilsTest = preload("res://addons/pgdecs/ecs/tests/unit/ecs_entity_ids_utils_test.gd")
const _EntityIdsPoolTest = preload("res://addons/pgdecs/ecs/tests/unit/ecs_entity_ids_pool_test.gd")
const _ArchetypeTest = preload("res://addons/pgdecs/ecs/tests/unit/ecs_archetype_test.gd")
const _BitMaskTest = preload("res://addons/pgdecs/ecs/tests/unit/ecs_bit_mask_test.gd")
const _SparseSetTest = preload("res://addons/pgdecs/ecs/tests/unit/ecs_sparse_set_test.gd")
const _ComponentFactoryTest = preload("res://addons/pgdecs/ecs/tests/unit/ecs_component_factory_test.gd")
const _ComponentArrayTest = preload("res://addons/pgdecs/ecs/tests/unit/ecs_component_array_test.gd")
const _ManagerTest = preload("res://addons/pgdecs/ecs/tests/unit/ecs_manager_test.gd")
const _ManagerArchetypeTransitionTest = preload("res://addons/pgdecs/ecs/tests/unit/ecs_manager_archetype_transition_test.gd")
const _QueryTest = preload("res://addons/pgdecs/ecs/tests/unit/ecs_query_test.gd")
const _QueryChunkTest = preload("res://addons/pgdecs/ecs/tests/unit/ecs_query_chunk_test.gd")
const _WorldStateTest = preload("res://addons/pgdecs/ecs/tests/unit/ecs_world_state_test.gd")
const _CommandBufferTest = preload("res://addons/pgdecs/ecs/tests/unit/ecs_command_buffer_test.gd")
const _SystemRunnerTest = preload("res://addons/pgdecs/ecs/tests/unit/ecs_system_runner_test.gd")
const _SystemChunkBaseTest = preload("res://addons/pgdecs/ecs/tests/unit/ecs_system_chunk_base_test.gd")
const _RegressionTest = preload("res://addons/pgdecs/ecs/tests/unit/ecs_regression_test.gd")
const _ArchetypeChunkTest = preload("res://addons/pgdecs/ecs/tests/unit/ecs_archetype_chunk_test.gd")
const _MembershipTest = preload("res://addons/pgdecs/ecs/tests/unit/ecs_membership_test.gd")
const _DenseIterationTest = preload("res://addons/pgdecs/ecs/tests/unit/ecs_dense_iteration_test.gd")
const _WorldDemoTest = preload("res://addons/pgdecs/ecs/tests/unit/ecs_world_demo_test.gd")

static func run_all(runner: ECSTestRunner) -> void:
	var suites: Array[RefCounted] = [
		_EntityIdsUtilsTest.new(),
		_EntityIdsPoolTest.new(),
		_ArchetypeTest.new(),
		_ArchetypeChunkTest.new(),
		_BitMaskTest.new(),
		_SparseSetTest.new(),
		_ComponentFactoryTest.new(),
		_ComponentArrayTest.new(),
		_ManagerTest.new(),
		_ManagerArchetypeTransitionTest.new(),
		_QueryTest.new(),
		_QueryChunkTest.new(),
		_WorldStateTest.new(),
		_CommandBufferTest.new(),
		_SystemRunnerTest.new(),
		_SystemChunkBaseTest.new(),
		_RegressionTest.new(),
		_MembershipTest.new(),
		_DenseIterationTest.new(),
		_WorldDemoTest.new()
	]
	var names: PackedStringArray = PackedStringArray([
		"EntityIdsUtils", "EntityIdsPool", "Archetype", "ArchetypeChunk", "BitMask", "SparseSet",
		"ComponentFactory", "ComponentArray", "ECSManager", "ManagerArchetypeTransition", "Query", "QueryChunk",
		"WorldState", "CommandBuffer", "SystemRunner", "SystemChunkBase", "Regression",
		"Membership", "DenseIteration", "WorldDemo"
	])
	print("--- ECS Unit Tests ---")
	for i in range(suites.size()):
		print("Suite: %s" % names[i])
		runner.run_suite(names[i], suites[i])
	print("--- Summary ---")
	runner.print_summary()
