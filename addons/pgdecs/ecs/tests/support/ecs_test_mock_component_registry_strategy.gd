class_name ECSTestMockComponentRegistryStrategy extends ECSComponentRegistryStrategy

@export var tags_to_register: Array[int] = []
@export var components_to_register: Dictionary[int, int] = {}

func get_tags() -> Array[int]:
	return tags_to_register

func get_components() -> Dictionary[int, int]:
	return components_to_register
