class_name ExampleBindIntentSystem extends ECSSystemBase

var _dependencies: ExampleEcsDependencies
var _query: ECSQuery

func _init(ecs: ECSManager, dependencies: ExampleEcsDependencies) -> void:
	super(ecs)
	_dependencies = dependencies
	_query = ECSQueryBuilder.new() \
		.with_component(ExampleIntentIds.INTENT_BIND_NODE) \
		.build(ecs)

func process_system(_delta: float) -> void:
	if _dependencies == null or _dependencies.node_pool == null:
		return
	var cb: ECSCommandBuffer = get_command_buffer()
	for entity_id: int in _query.get_entity_ids():
		var node: Node2D = _dependencies.node_pool.acquire()
		# Bind = структурное появление reference-компонента со ссылкой.
		# «Есть нода» становится выразимо через with_component(NODE).
		cb.add_component(entity_id, ExampleIntentIds.NODE, node)
		cb.remove_component(entity_id, ExampleIntentIds.INTENT_BIND_NODE)
