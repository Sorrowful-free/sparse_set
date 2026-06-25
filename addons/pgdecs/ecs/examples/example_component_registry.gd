class_name ExampleComponentRegistry extends ECSComponentRegistryStrategy

enum Component {
	POSITION = 1,
	VELOCITY = 2,
	VISUAL_TYPE = 10,
	VISUAL_SUBTYPE = 11,
	VISUAL_HANDLE = 12,
}

enum Tag {
	PROJECTILE = 100,
}

func get_tags() -> Array[int]:
	return []

func get_components() -> Dictionary[int, int]:
	return {
		Component.POSITION: TYPE_PACKED_VECTOR2_ARRAY,
		Component.VELOCITY: TYPE_PACKED_FLOAT32_ARRAY,
	}

static func create_demo() -> ExampleComponentRegistry:
	return ExampleComponentRegistry.new()
