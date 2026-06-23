extends RefCounted
class_name ECSWorldDemoTest

const POSITION_ID: int = 1
const VELOCITY_ID: int = 2

func test_demo_world_bootstrap(runner: ECSTestRunner) -> void:
	var world: ECSDemoWorld = ECSDemoWorld.new()
	world.bootstrap(100)
	var ecs: ECSManager = world.get_ecs_manager()
	var query: ECSQuery = ECSQueryBuilder.new().with_component(POSITION_ID).with_component(VELOCITY_ID).build(ecs)
	runner.assert_eq(query.get_entity_ids().size(), 100)
