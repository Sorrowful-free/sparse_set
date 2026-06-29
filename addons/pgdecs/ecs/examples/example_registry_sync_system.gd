class_name ExampleRegistrySyncSystem extends ECSSystemChunkBase

var _services: ExampleEcsServices

func _init(ecs: ECSManager, services: ExampleEcsServices) -> void:
	_services = services
	super(ecs)

func _build_query() -> ECSQuery:
	return ECSQueryBuilder.new() \
		.with_component(ExampleIntentComponentRegistryStrategy.Component.POSITION) \
		.with_component(ExampleIntentIds.NODE_SLOT) \
		.build(get_ecs_manager())

func process_chunk(chunk: ECSQueryChunk, _delta: float) -> void:
	if _services == null or _services.node_registry == null:
		return
	var slot_chunk: ECSComponentInt32ArrayChunk = chunk.get_component_chunk(
		ExampleIntentIds.NODE_SLOT
	) as ECSComponentInt32ArrayChunk
	var pos_chunk: ECSComponentVector2ArrayChunk = chunk.get_component_chunk(
		ExampleIntentComponentRegistryStrategy.Component.POSITION
	) as ECSComponentVector2ArrayChunk
	if slot_chunk == null or pos_chunk == null:
		return
	var slots: PackedInt32Array = chunk.get_dense_slots()
	var slot_buf: PackedInt32Array = slot_chunk.get_values_buffer()
	var pos_buf: PackedVector2Array = pos_chunk.get_values_buffer()
	for i: int in range(chunk.get_entity_count()):
		var slot: int = slot_buf[slots[i]]
		if slot < 0:
			continue
		var node: Node = _services.node_registry.get_node(slot)
		if node == null:
			continue
		# Stub: игра пишет global_position / transform из pos_buf[slots[i]]
		pass
