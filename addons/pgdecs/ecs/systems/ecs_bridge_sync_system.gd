class_name ECSBridgeSyncSystem extends ECSSystemBase

var _world: ECSWorld
var _bridge_type: int = 0

func _init(ecs_manager: ECSManager, world: ECSWorld, bridge_type: int) -> void:
	super(ecs_manager)
	_world = world
	_bridge_type = bridge_type

func update(delta: float) -> void:
	if _world == null:
		return
	var registry: ECSBridgeRegistry = _world.get_bridge_registry()
	if registry == null:
		return
	var backend: ECSBridgeBackend = registry.get_backend(_bridge_type)
	if backend == null:
		return
	backend.update(get_ecs_manager(), delta)
