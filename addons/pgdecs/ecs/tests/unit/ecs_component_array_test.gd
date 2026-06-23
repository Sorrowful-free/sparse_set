extends RefCounted
class_name ECSComponentArrayTest

const POSITION_ID: int = 1

func test_add_get_set_remove(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
	var pos: ECSComponentVector2Array = ecs.get_component_array(POSITION_ID) as ECSComponentVector2Array
	var entity_id: int = ecs.create_entity(POSITION_ID)
	pos.set_component(entity_id, Vector2(3.0, 4.0))
	runner.assert_eq(pos.get_component(entity_id), Vector2(3.0, 4.0))
	pos.remove_component(entity_id)
	runner.assert_false(pos.has_component(entity_id))

func test_batch_add_remove(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_FLOAT32_ARRAY)
	var health_id: int = 2
	ecs.register_component(health_id, TYPE_PACKED_FLOAT32_ARRAY)
	var ids: PackedInt64Array = ecs.create_entities(4, POSITION_ID, health_id)
	var health: ECSComponentFloat32Array = ecs.get_component_array(health_id) as ECSComponentFloat32Array
	for entity_id in ids:
		runner.assert_true(health.has_component(entity_id))
	ecs.destroy_entities(ids)
	for entity_id in ids:
		runner.assert_false(ecs.is_alive(entity_id))

func test_chunk_boundary(runner: ECSTestRunner) -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(POSITION_ID, TYPE_PACKED_INT32_ARRAY)
	var ids: PackedInt64Array = ecs.create_entities(300, POSITION_ID)
	var comp: ECSComponentInt32Array = ecs.get_component_array(POSITION_ID) as ECSComponentInt32Array
	runner.assert_gt(comp.size_chunks(), 1)
	for entity_id in ids:
		comp.set_component(entity_id, 42)
		runner.assert_eq(comp.get_component(entity_id), 42)
