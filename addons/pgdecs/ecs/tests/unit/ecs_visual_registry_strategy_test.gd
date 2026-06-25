extends GutTest
class_name ECSVisualRegistryStrategyTest

const _MOCK_STRATEGY = preload("res://addons/pgdecs/ecs/tests/support/ecs_test_mock_visual_registry_strategy.gd")
const _DISABLED_STRATEGY = preload("res://addons/pgdecs/ecs/tests/support/ecs_test_disabled_visual_registry_strategy.gd")

const VISUAL_TYPE: int = 1

func test_strategy_installs_registry_without_host() -> void:
	var world: ECSWorld = ECSWorld.new()
	add_child_autofree(world)
	var strategy := _MOCK_STRATEGY.new()
	var registry := ECSVisualRegistry.new()
	strategy.registry_to_return = registry
	var profile := ECSWorldProfile.new()
	profile.visual_registry_strategies = [strategy]
	world.apply_profile(profile)
	assert_eq(world.get_visual_registry(), registry)
	assert_eq(strategy.create_count, 1)
	assert_eq(strategy.last_host, null)

func test_strategy_receives_visual_host() -> void:
	var world: ECSWorld = ECSWorld.new()
	add_child_autofree(world)
	var host := ECSVisualHost.new()
	world.add_child(host)
	var strategy := _MOCK_STRATEGY.new()
	var profile := ECSWorldProfile.new()
	profile.visual_registry_strategies = [strategy]
	world.apply_profile(profile)
	assert_eq(strategy.last_host, host)

func test_disabled_visual_strategy_skipped() -> void:
	var world: ECSWorld = ECSWorld.new()
	add_child_autofree(world)
	var profile := ECSWorldProfile.new()
	profile.visual_registry_strategies = [_DISABLED_STRATEGY.new()]
	world.apply_profile(profile)
	assert_eq(world.get_visual_registry(), null)

func test_null_strategy_without_host_has_no_registry() -> void:
	var world: ECSWorld = ECSWorld.new()
	add_child_autofree(world)
	world.add_child(ECSVisualHost.new())
	var strategy := _MOCK_STRATEGY.new()
	strategy.registry_to_return = null
	var profile := ECSWorldProfile.new()
	profile.visual_registry_strategies = [strategy]
	world.apply_profile(profile)
	assert_eq(world.get_visual_registry(), null)

func test_world_syncs_registry_from_strategy() -> void:
	var world: ECSWorld = ECSWorld.new()
	add_child_autofree(world)
	var strategy := _MOCK_STRATEGY.new()
	var registry := ECSVisualRegistry.new()
	var backend := ECSTestMockVisualBackend.new()
	registry.register_backend(VISUAL_TYPE, backend)
	strategy.registry_to_return = registry
	var profile := ECSWorldProfile.new()
	profile.visual_registry_strategies = [strategy]
	world.apply_profile(profile)
	world._process(0.016)
	assert_eq(backend.sync_count, 1)

func test_world_without_host_or_strategy_has_no_registry() -> void:
	var world: ECSWorld = ECSWorld.new()
	add_child_autofree(world)
	world.apply_profile(ECSWorldProfile.new())
	assert_eq(world.get_visual_registry(), null)

func test_first_non_null_strategy_wins() -> void:
	var world: ECSWorld = ECSWorld.new()
	add_child_autofree(world)
	var first := _MOCK_STRATEGY.new()
	first.registry_to_return = null
	var second := _MOCK_STRATEGY.new()
	var registry := ECSVisualRegistry.new()
	second.registry_to_return = registry
	var profile := ECSWorldProfile.new()
	profile.visual_registry_strategies = [first, second]
	world.apply_profile(profile)
	assert_eq(world.get_visual_registry(), registry)
	assert_eq(first.create_count, 1)
	assert_eq(second.create_count, 1)

func test_multiple_strategies_merge_backends() -> void:
	var world: ECSWorld = ECSWorld.new()
	add_child_autofree(world)
	var backend_a := ECSTestMockVisualBackend.new()
	var backend_b := ECSTestMockVisualBackend.new()
	var registry_a := ECSVisualRegistry.new()
	registry_a.register_backend(1, backend_a)
	var registry_b := ECSVisualRegistry.new()
	registry_b.register_backend(2, backend_b)
	var first := _MOCK_STRATEGY.new()
	first.registry_to_return = registry_a
	var second := _MOCK_STRATEGY.new()
	second.registry_to_return = registry_b
	var profile := ECSWorldProfile.new()
	profile.visual_registry_strategies = [first, second]
	world.apply_profile(profile)
	var merged: ECSVisualRegistry = world.get_visual_registry()
	assert_eq(merged, registry_a)
	var ecs: ECSManager = world.get_ecs_manager()
	assert_eq(merged.acquire(1, 1, ecs), 2)
	assert_eq(merged.acquire(2, 1, ecs), 2)
	assert_eq(backend_a.acquire_count, 1)
	assert_eq(backend_b.acquire_count, 1)

func test_apply_profile_before_add_child_installs_visual_on_enter_tree() -> void:
	var world: ECSWorld = ECSWorld.new()
	var strategy := _MOCK_STRATEGY.new()
	strategy.return_null_without_host = true
	var registry := ECSVisualRegistry.new()
	strategy.registry_to_return = registry
	var profile := ECSWorldProfile.new()
	profile.visual_registry_strategies = [strategy]
	world.apply_profile(profile)
	assert_eq(world.get_visual_registry(), null)
	world.add_child(ECSVisualHost.new())
	add_child_autofree(world)
	assert_eq(world.get_visual_registry(), registry)
	assert_eq(strategy.create_count, 2)
	assert_true(strategy.last_host != null)

func test_apply_profile_only_once() -> void:
	var world: ECSWorld = ECSWorld.new()
	add_child_autofree(world)
	var strategy := _MOCK_STRATEGY.new()
	var registry := ECSVisualRegistry.new()
	strategy.registry_to_return = registry
	var profile := ECSWorldProfile.new()
	profile.visual_registry_strategies = [strategy]
	world.apply_profile(profile)
	world.apply_profile(profile)
	assert_eq(strategy.create_count, 1)
