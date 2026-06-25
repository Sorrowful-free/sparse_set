class_name ECSTestMockBridgeBackendStrategy extends ECSBridgeBackendStrategy

var backend_to_return: ECSBridgeBackend = null
var create_count: int = 0
var last_host: ECSBridgeHost = null

func create_backend(host: ECSBridgeHost, _ecs: ECSManager, _world: ECSWorld) -> ECSBridgeBackend:
	create_count += 1
	last_host = host
	return backend_to_return
