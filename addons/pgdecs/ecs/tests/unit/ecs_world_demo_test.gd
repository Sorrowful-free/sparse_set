extends GutTest
class_name ECSWorldDemoTest

const _DEMO_WORLD = preload("res://addons/pgdecs/ecs/examples/demo_world.gd")

const POSITION_ID: int = 1
const VELOCITY_ID: int = 2

func test_demo_world_bootstrap() -> void:
	var world: ECSDemoWorld = add_child_autofree(_DEMO_WORLD.new())
	world.bootstrap(100)
	var ecs: ECSManager = world.get_ecs_manager()
	var query: ECSQuery = ECSQueryBuilder.new()\
		.with_component(POSITION_ID)\
		.with_component(VELOCITY_ID)\
		.build(ecs)
	assert_eq(query.get_entity_ids().size(), 100)

func test_demo_world_moves_entities() -> void:
	var world: ECSDemoWorld = add_child_autofree(_DEMO_WORLD.new())
	world.bootstrap(10, 10.0)
	var ecs: ECSManager = world.get_ecs_manager()
	var positions: ECSComponentVector2Array = ecs.get_component_array(POSITION_ID)
	var entity_ids: PackedInt64Array = ECSQueryBuilder.new()\
		.with_component(POSITION_ID)\
		.with_component(VELOCITY_ID)\
		.build(ecs).get_entity_ids()
	var before: Vector2 = positions.get_component(entity_ids[0])
	# DemoMovementSystem — run_group simulation → _physics_process, не _process.
	world._physics_process(0.1)
	var after: Vector2 = positions.get_component(entity_ids[0])
	assert_ne(after, before)
	assert_gt(after.x, before.x)
