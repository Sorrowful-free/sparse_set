extends GutTest
class_name ECSBridgeSyncTest

const BRIDGE_TYPE: int = 1

func test_sync_system_updates_backend() -> void:
	var world: ECSWorld = ECSWorld.new()
	add_child_autofree(world)
	world.add_child(ECSBridgeHost.new())
	var backend := ECSTestMockBridgeBackend.new()
	var backend_strategy := ECSTestMockBridgeBackendStrategy.new()
	backend_strategy.bridge_type = BRIDGE_TYPE
	backend_strategy.backend_to_return = backend
	var profile := ECSWorldProfile.new()
	profile.bridge_registry_strategy = ECSTestBridgeComponentIds.make_registry_strategy([backend_strategy])
	var sync_strategy := ECSBridgeSyncStrategy.new()
	sync_strategy.bridge_type = BRIDGE_TYPE
	sync_strategy.run_group = ECSSystemRunGroups.FRAME
	profile.system_strategies = [sync_strategy]
	world.apply_profile(profile)
	world.run_system_group(ECSSystemRunGroups.FRAME, 0.016)
	assert_eq(backend.update_count, 1)

func test_sync_skips_when_registry_missing() -> void:
	var world: ECSWorld = ECSWorld.new()
	add_child_autofree(world)
	var sync_strategy := ECSBridgeSyncStrategy.new()
	sync_strategy.bridge_type = BRIDGE_TYPE
	sync_strategy.run_group = ECSSystemRunGroups.FRAME
	var profile := ECSWorldProfile.new()
	profile.system_strategies = [sync_strategy]
	world.apply_profile(profile)
	world.run_system_group(ECSSystemRunGroups.FRAME, 0.016)
	pass_test("no crash without registry")
