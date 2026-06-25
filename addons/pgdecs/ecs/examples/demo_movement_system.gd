class_name DemoMovementSystem extends ECSSystemChunkBase

var _speed_mul: float

func _init(ecs: ECSManager, speed_mul: float = 1.0) -> void:
	_speed_mul = speed_mul
	super(ecs)

func _build_query() -> ECSQuery:
	return ECSQueryBuilder.new()\
		.with_component(ExampleComponentRegistryStrategy.Component.POSITION)\
		.with_component(ExampleComponentRegistryStrategy.Component.VELOCITY)\
		.build(get_ecs_manager())

func process_chunk(chunk: ECSQueryChunk, delta: float) -> void:
	var pos_chunk: ECSComponentVector2ArrayChunk = chunk.get_component_chunk(
		ExampleComponentRegistryStrategy.Component.POSITION
	) as ECSComponentVector2ArrayChunk
	var vel_chunk: ECSComponentFloat32ArrayChunk = chunk.get_component_chunk(
		ExampleComponentRegistryStrategy.Component.VELOCITY
	) as ECSComponentFloat32ArrayChunk
	if pos_chunk == null or vel_chunk == null:
		return
	var slots: PackedInt32Array = chunk.get_dense_slots()
	var pos_buf: PackedVector2Array = pos_chunk.get_values_buffer()
	var vel_buf: PackedFloat32Array = vel_chunk.get_values_buffer()
	var speed: float = _speed_mul * delta
	for i: int in range(chunk.get_entity_count()):
		var slot: int = slots[i]
		pos_chunk.set_value_at_slot(slot, pos_buf[slot] + Vector2(vel_buf[slot] * speed, 0.0))
