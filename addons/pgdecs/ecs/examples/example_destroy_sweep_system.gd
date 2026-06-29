class_name ExampleDestroySweepSystem extends ECSSystemBase

var _query: ECSQuery

func _init(ecs: ECSManager) -> void:
	super(ecs)
	_query = ECSQueryBuilder.new() \
		.with_component(ExampleIntentIds.INTENT_DESTROY) \
		.build(ecs)

func update(_delta: float) -> void:
	var cb: ECSCommandBuffer = get_command_buffer()
	for entity_id: int in _query.get_entity_ids():
		cb.remove_component(entity_id, ExampleIntentIds.INTENT_DESTROY)
		cb.destroy_entity(entity_id)
