class_name ExampleIntentComponentRegistryStrategy extends ECSComponentRegistryStrategy

## Схема для intent pipeline example: POSITION + NODE (reference-компонент) + intent tags.

enum Component {
	POSITION = 1,
	NODE = ExampleIntentIds.NODE,
}

func get_tags() -> Array[int]:
	return [
		ExampleIntentIds.INTENT_BIND_NODE,
		ExampleIntentIds.INTENT_RELEASE,
		ExampleIntentIds.INTENT_DESTROY,
	]

func get_components() -> Dictionary[int, ECSComponent.Type]:
	return {
		Component.POSITION: ECSComponent.Type.PACKED_VECTOR2,
		Component.NODE: ECSComponent.Type.NODE2D,
	}
