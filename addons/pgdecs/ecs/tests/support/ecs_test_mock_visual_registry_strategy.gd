class_name ECSTestMockVisualRegistryStrategy extends ECSVisualRegistryStrategy

var registry_to_return: ECSVisualRegistry = null
var create_count: int = 0
var last_host: ECSVisualHost = null

func create_registry(_ecs: ECSManager, _world: ECSWorld, host: ECSVisualHost = null) -> ECSVisualRegistry:
	create_count += 1
	last_host = host
	return registry_to_return
