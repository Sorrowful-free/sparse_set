class_name ECSTestMockComponentRegistryStrategy extends ECSComponentRegistryStrategy

@export var tags_to_register: Array[int] = []
## Не @export: значения — enum ECSComponent.Type (в inspector не редактируется).
var components_to_register: Dictionary[int, ECSComponent.Type] = {}

func get_tags() -> Array[int]:
	return tags_to_register

func get_components() -> Dictionary[int, ECSComponent.Type]:
	return components_to_register
