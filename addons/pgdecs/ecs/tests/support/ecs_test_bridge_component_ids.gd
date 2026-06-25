class_name ECSTestBridgeComponentIds extends RefCounted

## Тестовые id bridge-компонентов для unit-тестов.
const BRIDGE_TYPE: int = 10
const BRIDGE_HANDLE: int = 11
const TAG_BRIDGE: int = 20
const TAG_PENDING_ACQUIRE: int = 21
const TAG_PENDING_RELEASE: int = 22

static func make_resource() -> ECSBridgeComponentIds:
	var ids := ECSBridgeComponentIds.new()
	ids.bridge_type_id = BRIDGE_TYPE
	ids.bridge_handle_id = BRIDGE_HANDLE
	ids.tag_bridge = TAG_BRIDGE
	ids.tag_pending_acquire = TAG_PENDING_ACQUIRE
	ids.tag_pending_release = TAG_PENDING_RELEASE
	return ids

static func register_schema(ecs: ECSManager) -> void:
	ecs.register_component(BRIDGE_TYPE, TYPE_PACKED_INT32_ARRAY)
	ecs.register_component(BRIDGE_HANDLE, TYPE_PACKED_INT32_ARRAY)
	ecs.register_tag(TAG_BRIDGE)
	ecs.register_tag(TAG_PENDING_ACQUIRE)
	ecs.register_tag(TAG_PENDING_RELEASE)

static func make_registry_strategy(
	backend_strategies: Array[ECSBridgeBackendStrategy],
) -> ECSBridgeRegistryStrategy:
	var strategy := ECSBridgeRegistryStrategy.new()
	strategy.component_ids = make_resource()
	strategy.backend_strategies = backend_strategies
	return strategy
