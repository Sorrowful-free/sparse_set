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

func get_components() -> Dictionary[int, ECSComponent.Type]:
	return {
		Component.POSITION: ECSComponent.Type.PACKED_VECTOR2,
		Component.VELOCITY: ECSComponent.Type.PACKED_FLOAT32,
	}

static func create_demo() -> ExampleComponentRegistryStrategy:
	return ExampleComponentRegistryStrategy.new()
