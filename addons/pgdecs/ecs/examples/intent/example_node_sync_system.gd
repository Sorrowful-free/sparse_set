class_name ExampleNodeSyncSystem extends ECSSystemChunkBase

var _dependencies: ExampleEcsDependencies

func _init(ecs: ECSManager, dependencies: ExampleEcsDependencies) -> void:
	_dependencies = dependencies
	super(ecs)

func build_query() -> ECSQuery:
	return ECSQueryBuilder.new() \
		.with_component(ExampleIntentComponentRegistryStrategy.Component.POSITION) \
		.with_component(ExampleIntentIds.NODE) \
		.build(get_ecs_manager())

func process_chunk(chunk: ECSQueryChunk, _delta: float) -> void:
	if _dependencies == null:
		return
	var node_chunk: ECSComponentNode2DArrayChunk = chunk.get_component_chunk(
		ExampleIntentIds.NODE
	) as ECSComponentNode2DArrayChunk
	var pos_chunk: ECSComponentPackedVector2ArrayChunk = chunk.get_component_chunk(
		ExampleIntentComponentRegistryStrategy.Component.POSITION
	) as ECSComponentPackedVector2ArrayChunk
	if node_chunk == null or pos_chunk == null:
		return
	var slots: PackedInt32Array = chunk.get_dense_slots()
	var node_buf: Array[Node2D] = node_chunk.get_values_buffer()
	var pos_buf: PackedVector2Array = pos_chunk.get_values_buffer()
	for i: int in range(chunk.get_entity_count()):
		var slot: int = slots[i]
		var node: Node2D = node_buf[slot]
		# Ссылка на Node не обнуляется автоматически при free() — нужен guard.
		if node == null or not is_instance_valid(node):
			continue
		node.global_position = pos_buf[slot]
