class_name ExampleMoverBlueprint extends ECSEntityBlueprint

@export var initial_velocity: float = 1.0

func build_component_ids() -> PackedInt64Array:
	return PackedInt64Array([
		ExampleComponentRegistryStrategy.Component.POSITION,
		ExampleComponentRegistryStrategy.Component.VELOCITY,
	])

func apply_defaults(buf: ECSCommandBuffer, entity_id: int) -> void:
	buf.set_component_value(
		entity_id,
		ExampleComponentRegistryStrategy.Component.VELOCITY,
		initial_velocity
	)
