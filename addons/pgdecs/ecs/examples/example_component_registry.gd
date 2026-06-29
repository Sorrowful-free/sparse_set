class_name ExampleComponentRegistryStrategy extends ECSComponentRegistryStrategy

enum Component {
	POSITION = 1,
	VELOCITY = 2,
}

## Пример тега для игровой схемы (не входит в [method create_demo]).
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

static func create_demo() -> ExampleComponentRegistryStrategy:
	return ExampleComponentRegistryStrategy.new()
