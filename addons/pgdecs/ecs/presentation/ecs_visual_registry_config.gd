class_name ECSVisualRegistryConfig extends Resource

func create_registry(_world: ECSWorld, _context: ECSVisualHostContext) -> ECSVisualRegistry:
	push_error("ECSVisualRegistryConfig.create_registry: override in subclass")
	return null
