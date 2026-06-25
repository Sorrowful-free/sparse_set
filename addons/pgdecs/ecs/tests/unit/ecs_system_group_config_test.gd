extends GutTest
class_name ECSSystemGroupConfigTest

func test_default_group_configs_preset() -> void:
	var configs: Array[ECSSystemGroupConfig] = ECSSystemRunGroups.default_group_configs()
	assert_eq(configs.size(), 3)
	assert_eq(configs[0].group, ECSSystemRunGroups.SIMULATION)
	assert_eq(configs[0].process_hook, ECSSystemGroupConfig.ProcessHook.PHYSICS_PROCESS)
	assert_eq(configs[1].group, ECSSystemRunGroups.NETWORK)
	assert_eq(configs[1].hz, 20.0)
	assert_eq(configs[2].group, ECSSystemRunGroups.FRAME)
	assert_eq(configs[2].execution_order, 10)

func test_profile_resolve_empty_system_groups() -> void:
	var world_profile := ECSWorldProfile.new()
	var resolved: Array[ECSSystemGroupConfig] = world_profile.resolve_system_groups()
	assert_eq(resolved.size(), 3)
