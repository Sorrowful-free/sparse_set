class_name ExampleReleaseIntentSystem extends ECSSystemBase

var _dependencies: ExampleEcsDependencies
var _query: ECSQuery

func _init(ecs: ECSManager, dependencies: ExampleEcsDependencies) -> void:
	super(ecs)
	_dependencies = dependencies
	_query = ECSQueryBuilder.new() \
		.with_component(ExampleIntentIds.INTENT_RELEASE) \
		.build(ecs)

func update(_delta: float) -> void:
	if _dependencies == null or _dependencies.node_registry == null:
		return
	var ecs: ECSManager = get_ecs_manager()
	var slots: ECSComponentInt32Array = ecs.get_component_array(ExampleIntentIds.NODE_SLOT)
	if slots == null:
		return
	var cb: ECSCommandBuffer = get_command_buffer()
	for entity_id: int in _query.get_entity_ids():
		var slot: int = slots.get_component(entity_id)
		if slot >= 0:
			_dependencies.node_registry.release(slot)
			slots.set_component(entity_id, ExampleIntentIds.INVALID_SLOT)
		cb.remove_component(entity_id, ExampleIntentIds.INTENT_RELEASE)
