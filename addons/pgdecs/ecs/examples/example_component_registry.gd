class_name ExampleComponentRegistryStrategy extends ECSComponentRegistryStrategy

enum Component {
	POSITION = 1,
	VELOCITY = 2,
	## Зарегистрируйте через [method create_with_visual], если нужен visual layer.
	VISUAL_TYPE = 10,
	VISUAL_SUBTYPE = 11,
	VISUAL_HANDLE = 12,
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
	if _include_visual_components:
		components[Component.VISUAL_TYPE] = TYPE_PACKED_INT32_ARRAY
		components[Component.VISUAL_SUBTYPE] = TYPE_PACKED_INT32_ARRAY
		components[Component.VISUAL_HANDLE] = TYPE_PACKED_INT32_ARRAY
	return components

static func create_demo() -> ExampleComponentRegistryStrategy:
	return ExampleComponentRegistryStrategy.new()

static func create_with_visual() -> ExampleComponentRegistryStrategy:
	var strategy := ExampleComponentRegistryStrategy.new()
	strategy._include_visual_components = true
	return strategy

var _include_visual_components: bool = false
