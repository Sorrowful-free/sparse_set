class_name ExampleRegistrySyncSystem extends ECSSystemChunkBase

var _dependencies: ExampleEcsDependencies

func _init(ecs: ECSManager, dependencies: ExampleEcsDependencies) -> void:
	_dependencies = dependencies
	super(ecs)

func build_query() -> ECSQuery:
	return ECSQueryBuilder.new() \
		.with_component(ExampleIntentComponentRegistryStrategy.Component.POSITION) \
		.with_component(ExampleIntentIds.NODE_SLOT) \
		.build(get_ecs_manager())

func process_chunk(chunk: ECSQueryChunk, _delta: float) -> void:
	if _dependencies == null or _dependencies.node_registry == null:
		return
	var slot_chunk: ECSComponentPackedInt32ArrayChunk = chunk.get_component_chunk(
		ExampleIntentIds.NODE_SLOT
	) as ECSComponentPackedInt32ArrayChunk
	var pos_chunk: ECSComponentPackedVector2ArrayChunk = chunk.get_component_chunk(
		ExampleIntentComponentRegistryStrategy.Component.POSITION
	) as ECSComponentPackedVector2ArrayChunk
	if slot_chunk == null or pos_chunk == null:
		return
	var slots: PackedInt32Array = chunk.get_dense_slots()
	var slot_buf: PackedInt32Array = slot_chunk.get_values_buffer()
	var pos_buf: PackedVector2Array = pos_chunk.get_values_buffer()
	for i: int in range(chunk.get_entity_count()):
		var slot: int = slot_buf[slots[i]]
		if slot < 0:
			continue
		var node: Node = _dependencies.node_registry.get_node(slot)
		if node == null:
			continue
		# Stub: игра пишет global_position / transform из pos_buf[slots[i]]
		pass
