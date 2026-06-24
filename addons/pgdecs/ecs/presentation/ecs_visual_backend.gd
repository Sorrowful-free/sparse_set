class_name ECSVisualBackend extends RefCounted

## Один visual_type (рендерер / MultiMesh / node pool). Реализация — в игре.
var visual_type: int = 0

func acquire_for_entity(_entity_id: int, _ecs: ECSManager) -> int:
	push_error("ECSVisualBackend.acquire_for_entity: override in subclass")
	return -1

func release_handle(_handle: int) -> void:
	pass

func on_bound(_entity_id: int, _handle: int, _ecs: ECSManager) -> void:
	pass

func sync(_ecs: ECSManager, _delta: float) -> void:
	pass
