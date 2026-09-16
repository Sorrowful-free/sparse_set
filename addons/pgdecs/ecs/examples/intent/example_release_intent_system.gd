class_name ExampleReleaseIntentSystem extends ECSSystemBase

var _dependencies: ExampleEcsDependencies
var _query: ECSQuery

func _init(ecs: ECSManager, dependencies: ExampleEcsDependencies) -> void:
	super(ecs)
	_dependencies = dependencies
	_query = ECSQueryBuilder.new() \
		.with_component(ExampleIntentIds.INTENT_RELEASE) \
		.build(ecs)

func process_system(_delta: float) -> void:
	if _dependencies == null or _dependencies.node_pool == null:
		return
	var ecs: ECSManager = get_ecs_manager()
	var nodes: ECSComponentNode2DArray = ecs.get_component_array(
		ExampleIntentIds.NODE
	) as ECSComponentNode2DArray
	if nodes == null:
		return
	var cb: ECSCommandBuffer = get_command_buffer()
	for entity_id: int in _query.get_entity_ids():
		if ecs.has_component(entity_id, ExampleIntentIds.NODE):
			var node: Node2D = nodes.get_component(entity_id)
			if node != null:
				_dependencies.node_pool.release(node)
			# Release = структурное исчезновение reference-компонента (без int-slot и без -1).
			cb.remove_component(entity_id, ExampleIntentIds.NODE)
		cb.remove_component(entity_id, ExampleIntentIds.INTENT_RELEASE)
