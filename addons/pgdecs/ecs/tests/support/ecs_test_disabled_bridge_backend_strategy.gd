class_name ECSTestDisabledBridgeBackendStrategy extends ECSBridgeBackendStrategy

func create_backend(_host: ECSBridgeHost, _ecs: ECSManager, _world: ECSWorld) -> ECSBridgeBackend:
	push_error("ECSTestDisabledBridgeBackendStrategy.create_backend should not be called")
	return null
