extends GutTest
class_name ECSWorldProfileTest

const POSITION_ID: int = 1

func _make_component_registry() -> ECSComponentRegistryConfig:
	var reg := ECSComponentRegistryConfig.new()
	reg.components = {POSITION_ID: TYPE_PACKED_VECTOR2_ARRAY}
	return reg

func test_registry_apply() -> void:
	var ecs: ECSManager = ECSManager.new()
	var reg: ECSComponentRegistryConfig = _make_component_registry()
	reg.apply_to(ecs)
	ecs.create_entity([POSITION_ID])
	var query: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).build(ecs)
	assert_eq(query.get_entity_ids().size(), 1)

func test_strategy_install() -> void:
	var world: ECSWorld = add_child_autofree(ECSWorld.new())
	var world_profile := ECSWorldProfile.new()
	world_profile.component_registry_config = _make_component_registry()
	world_profile.system_strategies = [ECSTestMockInitStrategy.new()]
	world.apply_profile(world_profile)
	var systems: Array[ECSSystemBase] = world.get_system_runner().get_systems()
	assert_eq(systems.size(), 1)
	world.get_system_runner().run(0.0)
	var sys: ECSTestCountSystem = systems[0] as ECSTestCountSystem
	assert_eq(sys.update_count, 1)

func test_disabled_strategy_skipped() -> void:
	var world: ECSWorld = add_child_autofree(ECSWorld.new())
	var world_profile := ECSWorldProfile.new()
	world_profile.system_strategies = [ECSTestDisabledInitStrategy.new()]
	world.apply_profile(world_profile)
	assert_eq(world.get_system_runner().get_systems().size(), 0)

func test_world_apply_profile() -> void:
	var world: ECSWorld = add_child_autofree(ECSWorld.new())
	var world_profile := ECSWorldProfile.new()
	world_profile.component_registry_config = _make_component_registry()
	world.apply_profile(world_profile)
	assert_eq(world.get_ecs_manager() != null, true)
	assert_eq(world.get_system_runner() != null, true)
