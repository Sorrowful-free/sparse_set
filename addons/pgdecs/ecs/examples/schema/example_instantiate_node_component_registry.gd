extends ECSComponentRegistryStrategy
class_name ExampleInstantiateNodeComponentRegistryStrategy

enum Component {
	POSITION = 1,
	VISUAL = 20,
	PACKED_SCENE = 30
}

func get_tags() -> Array[int]:
	return []

func get_components() -> Dictionary[int, ECSComponent.Type]:
	return {
		Component.POSITION: ECSComponent.Type.PACKED_VECTOR3,
		Component.VISUAL: ECSComponent.Type.NODE3D,
		Component.PACKED_SCENE: ECSComponent.Type.PACKED_SCENE,
	}
