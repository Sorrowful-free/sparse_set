extends GutTest
class_name ECSBridgeRegistryTest

const BRIDGE_TYPE: int = 1
const BRIDGE_TYPE_COMP: int = 10
const BRIDGE_HANDLE_COMP: int = 11

func test_registry_acquire_release_via_components() -> void:
	var registry := ECSBridgeRegistry.new()
	registry.bridge_type_component_id = BRIDGE_TYPE_COMP
	registry.bridge_handle_component_id = BRIDGE_HANDLE_COMP
	var backend := ECSTestMockBridgeBackend.new()
	registry.register_backend(BRIDGE_TYPE, backend)
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(BRIDGE_TYPE_COMP, TYPE_PACKED_INT32_ARRAY)
	ecs.register_component(BRIDGE_HANDLE_COMP, TYPE_PACKED_INT32_ARRAY)
	var entity_id: int = ecs.create_entity([BRIDGE_TYPE_COMP, BRIDGE_HANDLE_COMP])
	var handle: int = registry.acquire(BRIDGE_TYPE, entity_id, ecs)
	assert_eq(handle, 2)
	assert_eq(backend.acquire_count, 1)
	var types: ECSComponentInt32Array = ecs.get_component_array(BRIDGE_TYPE_COMP)
	var handles: ECSComponentInt32Array = ecs.get_component_array(BRIDGE_HANDLE_COMP)
	types.set_component(entity_id, BRIDGE_TYPE)
	handles.set_component(entity_id, handle)
	registry.release_entity(entity_id, ecs)
	assert_eq(backend.release_count, 1)
	assert_eq(backend.get_active_entities().size(), 0)
	var handle2: int = registry.acquire(BRIDGE_TYPE, 99, ecs)
	assert_eq(handle2, 2)

func test_backend_update_tracks_active() -> void:
	var registry := ECSBridgeRegistry.new()
	var backend := ECSTestMockBridgeBackend.new()
	registry.register_backend(BRIDGE_TYPE, backend)
	var ecs: ECSManager = ECSManager.new()
	ecs.register_component(BRIDGE_TYPE_COMP, TYPE_PACKED_INT32_ARRAY)
	var entity_id: int = ecs.create_entity([BRIDGE_TYPE_COMP])
	var handle: int = registry.acquire(BRIDGE_TYPE, entity_id, ecs)
	assert_eq(handle, 2)
	assert_eq(backend.get_active_entities(), [entity_id])
	backend.update(ecs, 0.016)
	assert_eq(backend.update_count, 1)

func test_unknown_bridge_type_returns_negative() -> void:
	var registry := ECSBridgeRegistry.new()
	var ecs: ECSManager = ECSManager.new()
	assert_eq(registry.acquire(999, 1, ecs), -1)
	assert_push_warning("unknown bridge_type")

func test_apply_component_ids() -> void:
	var registry := ECSBridgeRegistry.new()
	var ids := ECSTestBridgeComponentIds.make_resource()
	registry.apply_component_ids(ids)
	assert_eq(registry.get_component_ids(), ids)
	assert_eq(registry.bridge_type_component_id, ECSTestBridgeComponentIds.BRIDGE_TYPE)
	assert_eq(registry.bridge_handle_component_id, ECSTestBridgeComponentIds.BRIDGE_HANDLE)

func test_host_resolves_slots_and_refresh() -> void:
	var host := ECSBridgeHost.new()
	add_child_autofree(host)
	var units := Node.new()
	units.name = &"Units"
	host.add_child(units)
	host.slots = {&"units": NodePath("Units")}
	host.refresh_slots()
	assert_eq(host.get_slot(&"units"), units)
	assert_true(host.get_slot(&"units") != null)
	assert_eq(host.get_slot(&"missing"), null)
