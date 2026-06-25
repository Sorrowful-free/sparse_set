class_name ECSTestDisabledVisualRegistryStrategy extends ECSVisualRegistryStrategy

func _init() -> void:
	enabled = false

func create_registry(_ecs: ECSManager, _world: ECSWorld, _host: ECSVisualHost = null) -> ECSVisualRegistry:
	push_error("ECSTestDisabledVisualRegistryStrategy should not be called")
	return ECSVisualRegistry.new()
