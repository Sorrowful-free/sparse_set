extends GutTest

const VALUE_ID: int = 1
const EXTRA_ID: int = 2

class _TestBlueprint extends ECSEntityBlueprint:
	var velocity_default: float = 5.0

	func build_component_ids() -> PackedInt64Array:
		return PackedInt64Array([VALUE_ID])

	func apply_defaults(buf: ECSCommandBuffer, entity_id: int) -> void:
		buf.set_component(entity_id, VALUE_ID, velocity_default)


func test_spawn_one_applies_defaults() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(VALUE_ID, ECSComponent.Type.PACKED_FLOAT32)
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
	var comp: ECSComponentPackedFloat32Array = ecs.get_component_array(VALUE_ID) as ECSComponentPackedFloat32Array
	assert_eq(comp.get_component(entity_ids[0]), 7.5)


func test_spawn_one_returns_temp_id() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(VALUE_ID, ECSComponent.Type.PACKED_FLOAT32)
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
	var vel: ECSComponentPackedFloat32Array = ecs.get_component_array(
		ExampleComponentRegistryStrategy.Component.VELOCITY
	) as ECSComponentPackedFloat32Array
	assert_eq(vel.get_component(entity_ids[0]), 2.5)

func test_build_default_values_applied_on_spawn() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(VALUE_ID, ECSComponent.Type.PACKED_FLOAT32)
	var blueprint: _DictBlueprint = _DictBlueprint.new()
	var buf: ECSCommandBuffer = ECSCommandBuffer.new(ecs)
	blueprint.spawn_one(buf)
	buf.execute()
	var entity_ids: PackedInt64Array = ECSQueryBuilder.new().with_component(VALUE_ID).build(ecs).get_entity_ids()
	var comp: ECSComponentPackedFloat32Array = ecs.get_component_array(VALUE_ID) as ECSComponentPackedFloat32Array
	assert_eq(comp.get_component(entity_ids[0]), 42.0)

func test_apply_defaults_super_keeps_dict_and_extra() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(VALUE_ID, ECSComponent.Type.PACKED_FLOAT32)
	ecs.register_component(EXTRA_ID, ECSComponent.Type.PACKED_FLOAT32)
	var blueprint: _HybridBlueprint = _HybridBlueprint.new()
	var buf: ECSCommandBuffer = ECSCommandBuffer.new(ecs)
	blueprint.spawn_one(buf)
	buf.execute()
	var entity_ids: PackedInt64Array = ECSQueryBuilder.new().with_component(VALUE_ID).build(ecs).get_entity_ids()
	var values: ECSComponentPackedFloat32Array = ecs.get_component_array(VALUE_ID) as ECSComponentPackedFloat32Array
	var extras: ECSComponentPackedFloat32Array = ecs.get_component_array(EXTRA_ID) as ECSComponentPackedFloat32Array
	assert_eq(values.get_component(entity_ids[0]), 3.0)
	assert_eq(extras.get_component(entity_ids[0]), 99.0)

class _DictBlueprint extends ECSEntityBlueprint:
	func build_component_ids() -> PackedInt64Array:
		return PackedInt64Array([VALUE_ID])

	func build_default_values() -> Dictionary:
		return {VALUE_ID: 42.0}

class _HybridBlueprint extends ECSEntityBlueprint:
	func build_component_ids() -> PackedInt64Array:
		return PackedInt64Array([VALUE_ID, EXTRA_ID])

	func build_default_values() -> Dictionary:
		return {VALUE_ID: 3.0}

	func apply_defaults(buf: ECSCommandBuffer, entity_id: int) -> void:
		super.apply_defaults(buf, entity_id)
		buf.set_component(entity_id, EXTRA_ID, 99.0)
