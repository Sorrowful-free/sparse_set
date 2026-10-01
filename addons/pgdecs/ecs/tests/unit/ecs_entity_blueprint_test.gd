extends GutTest

const VALUE_ID: int = 1
const EXTRA_ID: int = 2

class _TestBlueprint extends ECSEntityBlueprint:
	var velocity_default: float = 5.0

	func build_component_ids() -> PackedInt64Array:
		return PackedInt64Array([VALUE_ID])

	func apply_defaults(buf: ECSCommandBuffer, entity_id: int) -> void:
		buf.set_component(entity_id, VALUE_ID, velocity_default)

func test_spawn_batch_applies_per_index() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(VALUE_ID, ECSComponent.Type.PACKED_FLOAT32)
	var blueprint: _IndexBlueprint = _IndexBlueprint.new()
	var buf: ECSCommandBuffer = ECSCommandBuffer.new(ecs)
	var temp_ids: PackedInt64Array = blueprint.spawn_batch(buf, 4)
	assert_eq(temp_ids.size(), 4)
	for temp_id in temp_ids:
		assert_lt(temp_id, 0)
	buf.execute()
	var comp: ECSComponentPackedFloat32Array = ecs.get_component_array(VALUE_ID) as ECSComponentPackedFloat32Array
	var entity_ids: PackedInt64Array = ECSQueryBuilder.new().with_component(VALUE_ID).build(ecs).get_entity_ids()
	assert_eq(entity_ids.size(), 4)
	for i in range(entity_ids.size()):
		assert_eq(comp.get_component(entity_ids[i]), float(i) * 10.0)

class _IndexBlueprint extends ECSEntityBlueprint:
	func build_component_ids() -> PackedInt64Array:
		return PackedInt64Array([VALUE_ID])

	func apply_instance(buf: ECSCommandBuffer, entity_id: int, index: int) -> void:
		buf.set_component(entity_id, VALUE_ID, float(index) * 10.0)

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

func test_get_archetype_caches_normalized_ids() -> void:
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(VALUE_ID, ECSComponent.Type.PACKED_FLOAT32)
	ecs.register_component(EXTRA_ID, ECSComponent.Type.PACKED_FLOAT32)
	var blueprint: _TestBlueprint = _TestBlueprint.new()
	var first: PackedInt64Array = blueprint.get_archetype(ecs)
	var second: PackedInt64Array = blueprint.get_archetype(ecs)
	assert_eq(first, second)
	assert_eq(first.size(), 1)
	assert_eq(first[0], VALUE_ID)

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

# --- node bindings ----------------------------------------------------------

const NODE_ID: int = 3

func _make_node3d_scene() -> PackedScene:
	var root: Node3D = Node3D.new()
	var packed: PackedScene = PackedScene.new()
	packed.pack(root)
	root.free()
	return packed

class _BoundBlueprint extends ECSEntityBlueprint:
	var node_scene: PackedScene

	func build_component_ids() -> PackedInt64Array:
		return PackedInt64Array([VALUE_ID])

func _register_bound_schema(ecs: ECSManager) -> void:
	ecs.register_component(VALUE_ID, ECSComponent.Type.PACKED_FLOAT32)
	ecs.register_component(NODE_ID, ECSComponent.Type.NODE3D)

func test_binding_component_id_added_to_archetype() -> void:
	var ecs: ECSManager = ECSManager.new()
	_register_bound_schema(ecs)
	var blueprint: _BoundBlueprint = _BoundBlueprint.new()
	blueprint.node_scene = _make_node3d_scene()
	var ids: PackedInt64Array = blueprint.get_component_ids()
	assert_eq(ids.size(), 2)
	assert_true(ids.has(VALUE_ID))
	assert_true(ids.has(NODE_ID))

func test_binding_without_scene_is_noop() -> void:
	var ecs: ECSManager = ECSManager.new()
	_register_bound_schema(ecs)
	var blueprint: _BoundBlueprint = _BoundBlueprint.new()
	var ids: PackedInt64Array = blueprint.get_component_ids()
	assert_eq(ids.size(), 1, "binding без сцены не добавляет компонент")
	assert_false(ids.has(NODE_ID))

func test_spawn_one_bound_sets_component_and_attaches_to_host() -> void:
	var ecs: ECSManager = ECSManager.new()
	_register_bound_schema(ecs)
	var blueprint: _BoundBlueprint = _BoundBlueprint.new()
	blueprint.node_scene = _make_node3d_scene()
	var host: Node3D = Node3D.new()
	var buf: ECSCommandBuffer = ECSCommandBuffer.new(ecs)
	var temp_id: int = blueprint.spawn_one_bound(buf, host)
	assert_lt(temp_id, 0)
	buf.execute()
	var entity_ids: PackedInt64Array = ECSQueryBuilder.new().with_component(NODE_ID).build(ecs).get_entity_ids()
	assert_eq(entity_ids.size(), 1)
	var nodes: ECSComponentNode3DArray = ecs.get_component_array(NODE_ID) as ECSComponentNode3DArray
	var node: Node3D = nodes.get_component(entity_ids[0])
	assert_not_null(node)
	# Контракт blueprint: нода добавлена к host. Членство в SceneTree — забота игры (host должен быть в дереве);
	# host здесь детачнутый, поэтому is_inside_tree() у ребёнка был бы false.
	assert_eq(node.get_parent(), host)
	assert_eq(host.get_child_count(), 1)
	host.free()

func test_spawn_one_bound_node_enters_scene_tree_when_host_is_in_tree() -> void:
	var ecs: ECSManager = ECSManager.new()
	_register_bound_schema(ecs)
	var blueprint: _BoundBlueprint = _BoundBlueprint.new()
	blueprint.node_scene = _make_node3d_scene()
	var host: Node3D = add_child_autofree(Node3D.new())
	assert_true(host.is_inside_tree(), "предпосылка: host в SceneTree")
	var buf: ECSCommandBuffer = ECSCommandBuffer.new(ecs)
	blueprint.spawn_one_bound(buf, host)
	buf.execute()
	var entity_ids: PackedInt64Array = ECSQueryBuilder.new().with_component(NODE_ID).build(ecs).get_entity_ids()
	assert_eq(entity_ids.size(), 1)
	var nodes: ECSComponentNode3DArray = ecs.get_component_array(NODE_ID) as ECSComponentNode3DArray
	var node: Node3D = nodes.get_component(entity_ids[0])
	assert_not_null(node)
	assert_true(node.is_inside_tree(), "host в дереве -> нода тоже в SceneTree")
	assert_eq(node.get_parent(), host)

func test_spawn_batch_bound_creates_one_instance_per_entity() -> void:
	var ecs: ECSManager = ECSManager.new()
	_register_bound_schema(ecs)
	var blueprint: _BoundBlueprint = _BoundBlueprint.new()
	blueprint.node_scene = _make_node3d_scene()
	var host: Node3D = Node3D.new()
	var buf: ECSCommandBuffer = ECSCommandBuffer.new(ecs)
	var temp_ids: PackedInt64Array = blueprint.spawn_batch_bound(buf, 3, host)
	assert_eq(temp_ids.size(), 3)
	buf.execute()
	var entity_ids: PackedInt64Array = ECSQueryBuilder.new().with_component(NODE_ID).build(ecs).get_entity_ids()
	assert_eq(entity_ids.size(), 3)
	var nodes: ECSComponentNode3DArray = ecs.get_component_array(NODE_ID) as ECSComponentNode3DArray
	var seen: Dictionary[int, bool] = {}
	for entity_id: int in entity_ids:
		var node: Node3D = nodes.get_component(entity_id)
		assert_not_null(node)
		seen[node.get_instance_id()] = true
	assert_eq(seen.size(), 3, "каждой сущности — свой инстанс")
	host.free()
