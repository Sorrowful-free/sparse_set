extends ECSVisualHost
class_name ECSTestVisualHost

var registry_to_return: ECSVisualRegistry = null

func build_registry(_world: ECSWorld) -> ECSVisualRegistry:
	return registry_to_return
