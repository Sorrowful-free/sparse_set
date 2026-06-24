class_name ExampleComponentRegistry extends ECSComponentRegistryConfig

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

static func create_demo() -> ExampleComponentRegistry:
	var reg := ExampleComponentRegistry.new()
	reg.components = {
		Component.POSITION: TYPE_PACKED_VECTOR2_ARRAY,
		Component.VELOCITY: TYPE_PACKED_FLOAT32_ARRAY,
	}
	return reg
