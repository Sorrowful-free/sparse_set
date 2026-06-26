class_name ExampleComponentRegistryStrategy extends ECSComponentRegistryStrategy

enum Component {
	POSITION = 1,
	VELOCITY = 2,
	## Зарегистрируйте через [method create_with_bridge], если нужен bridge layer.
	BRIDGE_TYPE = 10,
	BRIDGE_SUBTYPE = 11,
	BRIDGE_HANDLE = 12,
}

## Пример тега для игровой схемы (не входит в [method create_demo]).
enum Tag {
	PROJECTILE = 100,
}

func get_tags() -> Array[int]:
	return []

func get_components() -> Dictionary[int, int]:
	var components: Dictionary[int, int] = {
		Component.POSITION: TYPE_PACKED_VECTOR2_ARRAY,
		Component.VELOCITY: TYPE_PACKED_FLOAT32_ARRAY,
	}
	if _include_bridge_components:
		components[Component.BRIDGE_TYPE] = TYPE_PACKED_INT32_ARRAY
		components[Component.BRIDGE_SUBTYPE] = TYPE_PACKED_INT32_ARRAY
		components[Component.BRIDGE_HANDLE] = TYPE_PACKED_INT32_ARRAY
	return components

static func create_demo() -> ExampleComponentRegistryStrategy:
	return ExampleComponentRegistryStrategy.new()

static func create_with_bridge() -> ExampleComponentRegistryStrategy:
	var strategy := ExampleComponentRegistryStrategy.new()
	strategy._include_bridge_components = true
	return strategy

var _include_bridge_components: bool = false
