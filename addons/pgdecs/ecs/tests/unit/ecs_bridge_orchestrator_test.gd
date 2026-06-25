extends GutTest
class_name ECSBridgeOrchestratorTest

const BRIDGE_TYPE: int = 1

func _setup_world_with_orchestrator() -> Dictionary:
	var world: ECSWorld = ECSWorld.new()
	add_child_autofree(world)
	world.add_child(ECSBridgeHost.new())
	var ecs: ECSManager = world.get_ecs_manager()
	ECSTestBridgeComponentIds.register_schema(ecs)
	var backend := ECSTestMockBridgeBackend.new()
	var profile := ECSWorldProfile.new()
	var backend_strategy := ECSTestMockBridgeBackendStrategy.new()
	backend_strategy.bridge_type = BRIDGE_TYPE
	backend_strategy.backend_to_return = backend
	profile.bridge_registry_strategy = ECSTestBridgeComponentIds.make_registry_strategy([backend_strategy])
	var orch_strategy := ECSBridgeOrchestratorStrategy.new()
	orch_strategy.run_group = ECSSystemRunGroups.FRAME
	profile.system_strategies = [orch_strategy]
	world.apply_profile(profile)
	return {"world": world, "ecs": ecs, "backend": backend}

func test_orchestrator_acquires_pending_entity() -> void:
	var ctx: Dictionary = _setup_world_with_orchestrator()
	var world: ECSWorld = ctx.world
	var ecs: ECSManager = ctx.ecs
	var backend: ECSTestMockBridgeBackend = ctx.backend
	var entity_id: int = ecs.create_entity_packed(PackedInt64Array([
		ECSTestBridgeComponentIds.BRIDGE_TYPE,
		ECSTestBridgeComponentIds.BRIDGE_HANDLE,
		ECSTestBridgeComponentIds.TAG_PENDING_ACQUIRE,
	]))
	var types: ECSComponentInt32Array = ecs.get_component_array(ECSTestBridgeComponentIds.BRIDGE_TYPE)
	types.set_component(entity_id, BRIDGE_TYPE)
	world.run_system_group(ECSSystemRunGroups.FRAME, 0.016)
	assert_eq(backend.acquire_count, 1)
	assert_false(ecs.has_component(entity_id, ECSTestBridgeComponentIds.TAG_PENDING_ACQUIRE))
	assert_true(ecs.has_component(entity_id, ECSTestBridgeComponentIds.TAG_BRIDGE))
	var handles: ECSComponentInt32Array = ecs.get_component_array(ECSTestBridgeComponentIds.BRIDGE_HANDLE)
	assert_eq(handles.get_component(entity_id), 2)

func test_orchestrator_releases_and_destroys_pending_entity() -> void:
	var ctx: Dictionary = _setup_world_with_orchestrator()
	var world: ECSWorld = ctx.world
	var ecs: ECSManager = ctx.ecs
	var backend: ECSTestMockBridgeBackend = ctx.backend
	var entity_id: int = ecs.create_entity_packed(PackedInt64Array([
		ECSTestBridgeComponentIds.BRIDGE_TYPE,
		ECSTestBridgeComponentIds.BRIDGE_HANDLE,
		ECSTestBridgeComponentIds.TAG_BRIDGE,
		ECSTestBridgeComponentIds.TAG_PENDING_RELEASE,
	]))
	var types: ECSComponentInt32Array = ecs.get_component_array(ECSTestBridgeComponentIds.BRIDGE_TYPE)
	var handles: ECSComponentInt32Array = ecs.get_component_array(ECSTestBridgeComponentIds.BRIDGE_HANDLE)
	types.set_component(entity_id, BRIDGE_TYPE)
	handles.set_component(entity_id, 0)
	world.run_system_group(ECSSystemRunGroups.FRAME, 0.016)
	assert_eq(backend.release_count, 1)
	assert_false(ecs.is_alive(entity_id))
