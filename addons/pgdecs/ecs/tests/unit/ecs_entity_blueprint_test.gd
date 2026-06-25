extends GutTest

const VALUE_ID: int = 1
const EXTRA_ID: int = 2

class _TestBlueprint extends ECSEntityBlueprint:
	var velocity_default: float = 5.0

	func build_component_ids() -> PackedInt64Array:
		return PackedInt64Array([VALUE_ID])

	func apply_defaults(buf: ECSCommandBuffer, entity_id: int) -> void:
		buf.set_component_value(entity_id, VALUE_ID, velocity_default)

func test_spawn_batch_applies_per_index() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(VALUE_ID, TYPE_PACKED_FLOAT32_ARRAY)
	var blueprint: _IndexBlueprint = _IndexBlueprint.new()
	var buf: ECSCommandBuffer = ECSCommandBuffer.new(ecs)
	var temp_ids: PackedInt64Array = blueprint.spawn_batch(buf, 4)
	assert_eq(temp_ids.size(), 4)
	for temp_id in temp_ids:
		assert_lt(temp_id, 0)
	buf.execute()
	var comp: ECSComponentFloat32Array = ecs.get_component_array(VALUE_ID) as ECSComponentFloat32Array
	var entity_ids: PackedInt64Array = ECSQueryBuilder.new().with_component(VALUE_ID).build(ecs).get_entity_ids()
	assert_eq(entity_ids.size(), 4)
	for i in range(entity_ids.size()):
		assert_eq(comp.get_component(entity_ids[i]), float(i) * 10.0)

class _IndexBlueprint extends ECSEntityBlueprint:
	func build_component_ids() -> PackedInt64Array:
		return PackedInt64Array([VALUE_ID])

	func apply_instance(buf: ECSCommandBuffer, entity_id: int, index: int) -> void:
		buf.set_component_value(entity_id, VALUE_ID, float(index) * 10.0)

func test_spawn_one_applies_defaults() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(VALUE_ID, TYPE_PACKED_FLOAT32_ARRAY)
	var blueprint: _TestBlueprint = _TestBlueprint.new()
	blueprint.velocity_default = 7.5
	var buf: ECSCommandBuffer = ECSCommandBuffer.new(ecs)
	var temp_id: int = blueprint.spawn_one(buf)
	assert_lt(temp_id, 0)
	buf.execute()
	var query: ECSQuery = ECSQueryBuilder.new().with_component(VALUE_ID).build(ecs)
	var entity_ids: PackedInt64Array = query.get_entity_ids()
	assert_eq(entity_ids.size(), 1)
	assert_true(ecs.is_alive(entity_ids[0]))
	var comp: ECSComponentFloat32Array = ecs.get_component_array(VALUE_ID) as ECSComponentFloat32Array
	assert_eq(comp.get_component(entity_ids[0]), 7.5)

func test_get_archetype_caches_normalized_ids() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(VALUE_ID, TYPE_PACKED_FLOAT32_ARRAY)
	ecs.register_component(EXTRA_ID, TYPE_PACKED_FLOAT32_ARRAY)
	var blueprint: _TestBlueprint = _TestBlueprint.new()
	var first: PackedInt64Array = blueprint.get_archetype(ecs)
	var second: PackedInt64Array = blueprint.get_archetype(ecs)
	assert_eq(first, second)
	assert_eq(first.size(), 1)
	assert_eq(first[0], VALUE_ID)

func test_spawn_one_returns_temp_id() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(VALUE_ID, TYPE_PACKED_FLOAT32_ARRAY)
	var blueprint: _TestBlueprint = _TestBlueprint.new()
	var buf: ECSCommandBuffer = ECSCommandBuffer.new(ecs)
	var temp_id: int = blueprint.spawn_one(buf)
	assert_lt(temp_id, 0)
	buf.execute()
	var query: ECSQuery = ECSQueryBuilder.new().with_component(VALUE_ID).build(ecs)
	assert_eq(query.get_entity_ids().size(), 1)

func test_example_mover_blueprint_with_demo_schema() -> void:
	var ecs: ECSManager = ECSManager.new()
	ExampleComponentRegistryStrategy.create_demo().apply_to(ecs)
	var blueprint: ExampleMoverBlueprint = ExampleMoverBlueprint.new()
	blueprint.initial_velocity = 2.5
	var buf: ECSCommandBuffer = ECSCommandBuffer.new(ecs)
	blueprint.spawn_one(buf)
	buf.execute()
	var entity_ids: PackedInt64Array = ECSQueryBuilder.new().with_component(
		ExampleComponentRegistryStrategy.Component.VELOCITY
	).build(ecs).get_entity_ids()
	assert_eq(entity_ids.size(), 1)
	var vel: ECSComponentFloat32Array = ecs.get_component_array(
		ExampleComponentRegistryStrategy.Component.VELOCITY
	) as ECSComponentFloat32Array
	assert_eq(vel.get_component(entity_ids[0]), 2.5)
