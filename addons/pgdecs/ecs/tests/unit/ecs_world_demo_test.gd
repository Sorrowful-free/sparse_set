extends GutTest
class_name ECSWorldDemoTest

const POSITION_ID: int = 1
const VELOCITY_ID: int = 2

func test_demo_world_bootstrap() -> void:
	var world: ECSDemoWorld = add_child_autofree(ECSDemoWorld.new())
	world.bootstrap(100)
	var ecs: ECSManager = world.get_ecs_manager()
	var query: ECSQuery = ECSQueryBuilder.new()\
		.with_component(POSITION_ID)\
		.with_component(VELOCITY_ID)\
		.build(ecs)
	assert_eq(query.get_entity_ids().size(), 100)

func test_demo_world_moves_entities() -> void:
	var world: ECSDemoWorld = add_child_autofree(ECSDemoWorld.new())
	world.bootstrap(10, 10.0)
	var ecs: ECSManager = world.get_ecs_manager()
	var positions: ECSComponentVector2Array = ecs.get_component_array(POSITION_ID)
	var entity_ids: PackedInt64Array = ECSQueryBuilder.new()\
		.with_component(POSITION_ID)\
		.with_component(VELOCITY_ID)\
		.build(ecs).get_entity_ids()
	var before: Vector2 = positions.get_component(entity_ids[0])
	world._process(0.1)
	var after: Vector2 = positions.get_component(entity_ids[0])
	assert_ne(after, before)
	assert_gt(after.x, before.x)
