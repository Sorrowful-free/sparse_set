class_name ExampleIntentComponentRegistryStrategy extends ECSComponentRegistryStrategy

## Схема для intent pipeline example: POSITION + NODE_SLOT + intent tags.

enum Component {
	POSITION = 1,
	NODE_SLOT = ExampleIntentIds.NODE_SLOT,
}

func get_tags() -> Array[int]:
	return [
		ExampleIntentIds.INTENT_BIND_NODE,
		ExampleIntentIds.INTENT_RELEASE,
		ExampleIntentIds.INTENT_DESTROY,
	]

func get_components() -> Dictionary[int, int]:
	return {
		Component.POSITION: TYPE_PACKED_VECTOR2_ARRAY,
		Component.NODE_SLOT: TYPE_PACKED_INT32_ARRAY,
	}
