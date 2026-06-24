class_name ECSVisualSyncSystem extends ECSSystemBase

var _visual_registry: ECSVisualRegistry

func _init(ecs_manager: ECSManager, visual_registry: ECSVisualRegistry) -> void:
	super(ecs_manager)
	_visual_registry = visual_registry

func update(delta: float) -> void:
	if _visual_registry != null:
		_visual_registry.sync_all(get_ecs_manager(), delta)
