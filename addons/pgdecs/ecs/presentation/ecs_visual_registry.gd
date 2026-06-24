class_name ECSVisualRegistry extends RefCounted

func register_backend(_visual_type: int, _backend: ECSVisualBackend) -> void:
	push_error("ECSVisualRegistry.register_backend: override in subclass")

func acquire(_visual_type: int, _entity_id: int, _ecs: ECSManager) -> int:
	return -1

func release_entity(_entity_id: int) -> void:
	pass

func sync_all(_ecs: ECSManager, _delta: float) -> void:
	pass
