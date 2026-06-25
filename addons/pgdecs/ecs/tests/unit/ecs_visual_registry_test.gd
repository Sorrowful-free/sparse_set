extends GutTest
class_name ECSVisualRegistryTest

const VISUAL_TYPE: int = 1
const VISUAL_TYPE_COMP: int = 10
const VISUAL_HANDLE_COMP: int = 11

func test_registry_acquire_release_via_components() -> void:
	var registry := ECSVisualRegistry.new()
	registry.visual_type_component_id = VISUAL_TYPE_COMP
	registry.visual_handle_component_id = VISUAL_HANDLE_COMP
	var backend := ECSTestMockVisualBackend.new()
	registry.register_backend(VISUAL_TYPE, backend)
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(VISUAL_TYPE_COMP, TYPE_PACKED_INT32_ARRAY)
	ecs.register_component(VISUAL_HANDLE_COMP, TYPE_PACKED_INT32_ARRAY)
	var entity_id: int = ecs.create_entity([VISUAL_TYPE_COMP, VISUAL_HANDLE_COMP])
	var handle: int = registry.acquire(VISUAL_TYPE, entity_id, ecs)
	assert_eq(handle, 2)
	assert_eq(backend.acquire_count, 1)
	var types: ECSComponentInt32Array = ecs.get_component_array(VISUAL_TYPE_COMP)
	var handles: ECSComponentInt32Array = ecs.get_component_array(VISUAL_HANDLE_COMP)
	types.set_component(entity_id, VISUAL_TYPE)
	handles.set_component(entity_id, handle)
	registry.release_entity(entity_id, ecs)
	assert_eq(backend.release_count, 1)
	var handle2: int = registry.acquire(VISUAL_TYPE, 99, ecs)
	assert_eq(handle2, 2)

func test_registry_sync_all() -> void:
	var registry := ECSVisualRegistry.new()
	var backend := ECSTestMockVisualBackend.new()
	registry.register_backend(VISUAL_TYPE, backend)
	var ecs: ECSManager = ECSManager.new()
	registry.sync_all(ecs, 0.016)
	assert_eq(backend.sync_count, 1)

func test_unknown_visual_type_returns_negative() -> void:
	var registry := ECSVisualRegistry.new()
	var ecs: ECSManager = ECSManager.new()
	assert_eq(registry.acquire(999, 1, ecs), -1)
	assert_push_warning("unknown visual_type")

func test_host_resolves_slots() -> void:
	var host := ECSVisualHost.new()
	add_child_autofree(host)
	var units := Node.new()
	units.name = &"Units"
	host.add_child(units)
	host.slots = {&"units": NodePath("Units")}
	host._resolve_slots()
	assert_eq(host.get_slot(&"units"), units)
	assert_true(host.get_slot(&"units") != null)
	assert_eq(host.get_slot(&"missing"), null)
