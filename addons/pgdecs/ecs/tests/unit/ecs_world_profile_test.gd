extends GutTest
class_name ECSWorldProfileTest

const _MOCK_COMPONENT_REGISTRY = preload(
	"res://addons/pgdecs/ecs/tests/support/ecs_test_mock_component_registry_strategy.gd"
)

const POSITION_ID: int = 1

func _make_component_registry_strategy() -> ECSComponentRegistryStrategy:
	var strategy := _MOCK_COMPONENT_REGISTRY.new()
	strategy.components_to_register = {POSITION_ID: TYPE_PACKED_VECTOR2_ARRAY}
	return strategy

func test_registry_apply() -> void:
	var ecs: ECSManager = ECSManager.new()
	var strategy: ECSComponentRegistryStrategy = _make_component_registry_strategy()
	strategy.apply_to(ecs)
	ecs.create_entity([POSITION_ID])
	var query: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).build(ecs)
	assert_eq(query.get_entity_ids().size(), 1)

func test_strategy_install() -> void:
	var world: ECSWorld = add_child_autofree(ECSWorld.new())
	var world_profile := ECSWorldProfile.new()
	world_profile.component_registry_strategy = _make_component_registry_strategy()
	world_profile.system_strategies = [ECSTestMockSystemStrategy.new()]
	world.apply_profile(world_profile)
	var systems: Array[ECSSystemBase] = world.get_system_runner().get_systems()
	assert_eq(systems.size(), 1)
	world.get_system_runner().run(0.0)
	var sys: ECSTestCountSystem = systems[0] as ECSTestCountSystem
	assert_eq(sys.update_count, 1)

func test_disabled_strategy_skipped() -> void:
	var world: ECSWorld = add_child_autofree(ECSWorld.new())
	var world_profile := ECSWorldProfile.new()
	world_profile.system_strategies = [ECSTestDisabledSystemStrategy.new()]
	world.apply_profile(world_profile)
	assert_eq(world.get_system_runner().get_systems().size(), 0)

func test_world_apply_profile() -> void:
	var world: ECSWorld = add_child_autofree(ECSWorld.new())
	var world_profile := ECSWorldProfile.new()
	world_profile.component_registry_strategy = _make_component_registry_strategy()
	world.apply_profile(world_profile)
	assert_eq(world.get_ecs_manager() != null, true)
	assert_eq(world.get_system_runner() != null, true)

func test_apply_profile_twice_does_not_duplicate_systems() -> void:
	var world: ECSWorld = add_child_autofree(ECSWorld.new())
	var world_profile := ECSWorldProfile.new()
	world_profile.component_registry_strategy = _make_component_registry_strategy()
	world_profile.system_strategies = [ECSTestMockSystemStrategy.new()]
	world.apply_profile(world_profile)
	world.apply_profile(world_profile)
	assert_eq(world.get_system_runner().get_systems().size(), 1)

func test_reset_world_allows_reapply_profile() -> void:
	var world: ECSWorld = add_child_autofree(ECSWorld.new())
	var world_profile := ECSWorldProfile.new()
	world_profile.component_registry_strategy = _make_component_registry_strategy()
	world_profile.system_strategies = [ECSTestMockSystemStrategy.new()]
	world.apply_profile(world_profile)
	world.reset_world()
	world.apply_profile(world_profile)
	assert_eq(world.get_system_runner().get_systems().size(), 1)
	assert_true(world.is_profile_applied())

func test_disabled_component_registry_strategy_skips_registration() -> void:
	var world: ECSWorld = add_child_autofree(ECSWorld.new())
	var strategy := _make_component_registry_strategy()
	strategy.enabled = false
	var world_profile := ECSWorldProfile.new()
	world_profile.component_registry_strategy = strategy
	world.apply_profile(world_profile)
	assert_eq(world.get_ecs_manager().get_component_array(POSITION_ID), null)
