class_name ExampleMoverBlueprint extends ECSEntityBlueprint

@export var initial_velocity: float = 1.0

func build_component_ids() -> PackedInt64Array:
	return PackedInt64Array([
		ExampleComponentRegistryStrategy.Component.POSITION,
		ExampleComponentRegistryStrategy.Component.VELOCITY,
	])

func build_default_values() -> Dictionary:
	return {
		ExampleComponentRegistryStrategy.Component.VELOCITY: initial_velocity,
	}
