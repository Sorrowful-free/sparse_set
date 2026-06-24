extends GutTest
class_name ECSVisualRegistryTest

const VISUAL_TYPE: int = 1

func test_dispatcher_acquire_release() -> void:
	var dispatcher := ECSVisualRegistryDispatcher.new()
	var backend := ECSTestMockVisualBackend.new()
	dispatcher.register_backend(VISUAL_TYPE, backend)
	var ecs: ECSManager = ECSManager.new()
	var handle: int = dispatcher.acquire(VISUAL_TYPE, 42, ecs)
	assert_eq(handle, 2)
	assert_eq(backend.acquire_count, 1)
	assert_true(dispatcher.get_entity_mirror().has(42))
	dispatcher.release_entity(42)
	assert_eq(backend.release_count, 1)
	assert_false(dispatcher.get_entity_mirror().has(42))
	var handle2: int = dispatcher.acquire(VISUAL_TYPE, 99, ecs)
	assert_eq(handle2, 2)

func test_dispatcher_sync_all() -> void:
	var dispatcher := ECSVisualRegistryDispatcher.new()
	var backend := ECSTestMockVisualBackend.new()
	dispatcher.register_backend(VISUAL_TYPE, backend)
	var ecs: ECSManager = ECSManager.new()
	dispatcher.sync_all(ecs, 0.016)
	assert_eq(backend.sync_count, 1)

func test_visual_sync_system() -> void:
	var dispatcher := ECSVisualRegistryDispatcher.new()
	var backend := ECSTestMockVisualBackend.new()
	dispatcher.register_backend(VISUAL_TYPE, backend)
	var ecs: ECSManager = ECSManager.new()
	var sys := ECSVisualSyncSystem.new(ecs, dispatcher)
	sys.update(0.016)
	assert_eq(backend.sync_count, 1)

func test_unknown_visual_type_returns_negative() -> void:
	var dispatcher := ECSVisualRegistryDispatcher.new()
	var ecs: ECSManager = ECSManager.new()
	assert_eq(dispatcher.acquire(999, 1, ecs), -1)

func test_host_context_resolves_slots() -> void:
	var host := ECSVisualHost.new()
	add_child_autofree(host)
	var units := Node.new()
	units.name = &"Units"
	host.add_child(units)
	var binding := ECSVisualSceneBinding.new()
	binding.slots = {&"units": NodePath("Units")}
	host.scene_binding = binding
	var context := host.build_context()
	assert_eq(context.get_root(), host)
	assert_eq(context.get_node(&"units"), units)
	assert_true(context.has_slot(&"units"))
	assert_false(context.has_slot(&"missing"))

func test_world_builds_context_without_host() -> void:
	var world: ECSWorld = ECSWorld.new()
	add_child_autofree(world)
	var context := ECSVisualHostContext.from_world(world)
	assert_eq(context.get_root(), world)
