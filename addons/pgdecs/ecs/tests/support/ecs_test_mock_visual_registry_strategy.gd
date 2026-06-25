class_name ECSTestMockVisualRegistryStrategy extends ECSVisualRegistryStrategy

var registry_to_return: ECSVisualRegistry = null
var create_count: int = 0
var last_host: ECSVisualHost = null
var return_null_without_host: bool = false

func create_registry(_ecs: ECSManager, _world: ECSWorld, host: ECSVisualHost = null) -> ECSVisualRegistry:
	create_count += 1
	last_host = host
	if return_null_without_host and host == null:
		return null
	return registry_to_return
