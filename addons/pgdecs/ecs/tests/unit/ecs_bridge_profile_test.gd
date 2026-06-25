extends GutTest
class_name ECSBridgeProfileTest

const _MOCK_BACKEND_STRATEGY = preload("res://addons/pgdecs/ecs/tests/support/ecs_test_mock_bridge_backend_strategy.gd")
const _DISABLED_BACKEND_STRATEGY = preload("res://addons/pgdecs/ecs/tests/support/ecs_test_disabled_bridge_backend_strategy.gd")

const BRIDGE_TYPE: int = 1

func _make_profile_with_mock_backend(backend: ECSBridgeBackend) -> ECSWorldProfile:
	var profile := ECSWorldProfile.new()
	var backend_strategy := _MOCK_BACKEND_STRATEGY.new()
	backend_strategy.bridge_type = BRIDGE_TYPE
	backend_strategy.backend_to_return = backend
	profile.bridge_registry_strategy = ECSTestBridgeComponentIds.make_registry_strategy([backend_strategy])
	return profile

func test_profile_installs_registry_with_host() -> void:
	var world: ECSWorld = ECSWorld.new()
	add_child_autofree(world)
	var host := ECSBridgeHost.new()
	world.add_child(host)
	var backend := ECSTestMockBridgeBackend.new()
	var profile := _make_profile_with_mock_backend(backend)
	world.apply_profile(profile)
	var registry: ECSBridgeRegistry = world.get_bridge_registry()
	assert_true(registry != null)
	assert_eq(registry.get_backend(BRIDGE_TYPE), backend)
	assert_eq(registry.get_component_ids(), profile.bridge_registry_strategy.component_ids)

func test_profile_without_host_has_no_registry() -> void:
	var world: ECSWorld = ECSWorld.new()
	add_child_autofree(world)
	var profile := _make_profile_with_mock_backend(ECSTestMockBridgeBackend.new())
	world.apply_profile(profile)
	assert_eq(world.get_bridge_registry(), null)

func test_disabled_backend_strategy_skipped() -> void:
	var world: ECSWorld = ECSWorld.new()
	add_child_autofree(world)
	world.add_child(ECSBridgeHost.new())
	var disabled := _DISABLED_BACKEND_STRATEGY.new()
	disabled.enabled = false
	disabled.bridge_type = BRIDGE_TYPE
	var profile := ECSWorldProfile.new()
	profile.bridge_registry_strategy = ECSTestBridgeComponentIds.make_registry_strategy([disabled])
	world.apply_profile(profile)
	assert_eq(world.get_bridge_registry().get_backend(BRIDGE_TYPE), null)

func test_apply_profile_before_add_child_installs_bridge_on_enter_tree() -> void:
	var world: ECSWorld = ECSWorld.new()
	var backend := ECSTestMockBridgeBackend.new()
	var profile := _make_profile_with_mock_backend(backend)
	world.apply_profile(profile)
	assert_eq(world.get_bridge_registry(), null)
	world.add_child(ECSBridgeHost.new())
	add_child_autofree(world)
	assert_true(world.get_bridge_registry() != null)
	assert_eq(world.get_bridge_registry().get_backend(BRIDGE_TYPE), backend)

func test_apply_profile_only_once() -> void:
	var world: ECSWorld = ECSWorld.new()
	add_child_autofree(world)
	world.add_child(ECSBridgeHost.new())
	var backend_strategy := _MOCK_BACKEND_STRATEGY.new()
	backend_strategy.bridge_type = BRIDGE_TYPE
	backend_strategy.backend_to_return = ECSTestMockBridgeBackend.new()
	var profile := ECSWorldProfile.new()
	profile.bridge_registry_strategy = ECSTestBridgeComponentIds.make_registry_strategy([backend_strategy])
	world.apply_profile(profile)
	world.apply_profile(profile)
	assert_eq(backend_strategy.create_count, 1)

func test_mock_strategy_receives_bridge_host() -> void:
	var world: ECSWorld = ECSWorld.new()
	add_child_autofree(world)
	var host := ECSBridgeHost.new()
	world.add_child(host)
	var backend_strategy := _MOCK_BACKEND_STRATEGY.new()
	backend_strategy.bridge_type = BRIDGE_TYPE
	backend_strategy.backend_to_return = ECSTestMockBridgeBackend.new()
	var profile := ECSWorldProfile.new()
	profile.bridge_registry_strategy = ECSTestBridgeComponentIds.make_registry_strategy([backend_strategy])
	world.apply_profile(profile)
	assert_eq(backend_strategy.last_host, host)
