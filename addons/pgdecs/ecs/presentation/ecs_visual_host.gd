extends Node
class_name ECSVisualHost

## Якорь visual-сцены под [ECSWorld]. [member scene_binding] задаёт именованные ноды для backends.
@export var scene_binding: ECSVisualSceneBinding

func build_context() -> ECSVisualHostContext:
	return ECSVisualHostContext.new(self, scene_binding)
