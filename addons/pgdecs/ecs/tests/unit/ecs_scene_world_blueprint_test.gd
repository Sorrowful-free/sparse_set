extends GutTest
class_name ECSSceneWorldBlueprintTest

const DEFAULT_VALUE_ID: int = 101
const SCENE_VALUE_ID: int = 102


class _SceneSource extends Node:
	var scene_position: Vector2 = Vector2(4.0, 6.0)


class _SceneEntity extends ECSSceneEntityBlueprint:
	func build_component_ids() -> PackedInt64Array:
		return PackedInt64Array([DEFAULT_VALUE_ID, SCENE_VALUE_ID])

	func build_default_values() -> Dictionary:
		return {DEFAULT_VALUE_ID: 13.0}

	func apply_defaults(buf: ECSCommandBuffer, entity_id: int, source_node: Node) -> void:
		super.apply_defaults(buf, entity_id, source_node)
		var source: _SceneSource = source_node as _SceneSource
		if source != null:
			buf.set_component(entity_id, SCENE_VALUE_ID, source.scene_position)


class _InspectingSystemStrategy extends ECSSystemStrategy:
	var entity_count_when_created: int = -1

	func create_system(ecs: ECSManager, _world: ECSWorld = null) -> ECSSystemBase:
		entity_count_when_created = ECSQueryBuilder.new().with_component(
			SCENE_VALUE_ID
		).build(ecs).get_entity_ids().size()
		return ECSTestCountSystem.new(ecs)


func _make_profile(strategy: ECSSystemStrategy = null) -> ECSWorldProfile:
	var registry := ECSTestMockComponentRegistryStrategy.new()
	registry.components_to_register = {
		DEFAULT_VALUE_ID: ECSComponent.Type.PACKED_FLOAT32,
		SCENE_VALUE_ID: ECSComponent.Type.PACKED_VECTOR2,
	}
	var result := ECSWorldProfile.new()
	result.component_registry_strategy = registry
	if strategy != null:
		result.system_strategies = [strategy]
	return result


func _make_scene_world(assign_coordinator: bool, strategy: ECSSystemStrategy = null) -> Dictionary:
	var root := Node.new()
	var world := ECSWorld.new()
	var coordinator := ECSSceneWorldBlueprint.new()
	coordinator.scene_root = root
	world.add_child(coordinator)
	if assign_coordinator:
		world.scene_world_blueprint = coordinator

	var source := _SceneSource.new()
	var marker := _SceneEntity.new()
	source.add_child(marker)
	root.add_child(world)
	root.add_child(source)
	world.apply_profile(_make_profile(strategy))
	return {"root": root, "world": world, "source": source, "marker": marker}


func _scene_entity_ids(ecs: ECSManager) -> PackedInt64Array:
	return ECSQueryBuilder.new().with_component(SCENE_VALUE_ID).build(ecs).get_entity_ids()


func test_unassigned_coordinator_disables_scene_build() -> void:
	var setup: Dictionary = _make_scene_world(false)
	var root: Node = setup["root"]
	var world: ECSWorld = setup["world"]
	add_child_autofree(root)
	assert_eq(_scene_entity_ids(world.get_ecs_manager()).size(), 0)


func test_scene_marker_creates_entity_and_applies_source_value_and_defaults() -> void:
	var setup: Dictionary = _make_scene_world(true)
	var root: Node = setup["root"]
	var source: _SceneSource = setup["source"]
	var world: ECSWorld = setup["world"]
	add_child_autofree(root)

	var entity_ids: PackedInt64Array = _scene_entity_ids(world.get_ecs_manager())
	assert_eq(entity_ids.size(), 1)
	var entity_id: int = entity_ids[0]
	var default_values: ECSComponentPackedFloat32Array = world.get_ecs_manager().get_component_array(
		DEFAULT_VALUE_ID
	) as ECSComponentPackedFloat32Array
	var scene_values: ECSComponentPackedVector2Array = world.get_ecs_manager().get_component_array(
		SCENE_VALUE_ID
	) as ECSComponentPackedVector2Array
	assert_eq(default_values.get_component(entity_id), 13.0)
	assert_eq(scene_values.get_component(entity_id), source.scene_position)


func test_scene_bootstrap_precedes_system_creation_and_first_tick() -> void:
	var strategy := _InspectingSystemStrategy.new()
	var setup: Dictionary = _make_scene_world(true, strategy)
	var root: Node = setup["root"]
	var world: ECSWorld = setup["world"]
	add_child_autofree(root)

	assert_eq(strategy.entity_count_when_created, 1)
	var systems: Array[ECSSystemBase] = world.get_system_runner().get_systems()
	assert_eq(systems.size(), 1)
	world.get_system_runner().run(0.0)
	assert_eq((systems[0] as ECSTestCountSystem).update_count, 1)


func test_reapplying_profile_does_not_duplicate_scene_entities() -> void:
	var setup: Dictionary = _make_scene_world(true)
	var root: Node = setup["root"]
	var world: ECSWorld = setup["world"]
	var profile: ECSWorldProfile = world.profile
	add_child_autofree(root)

	world.apply_profile(profile)
	assert_eq(_scene_entity_ids(world.get_ecs_manager()).size(), 1)
