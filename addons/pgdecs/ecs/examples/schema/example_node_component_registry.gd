class_name ExampleNodeComponentRegistryStrategy extends ECSComponentRegistryStrategy

## Схема абстрактного примера blueprint-биндинга: данные (POSITION) + reference-компоненты нод.
## Точные типы: `VISUAL` → `Node3D`, `BODY` → `RigidBody3D`, `ANIMATION` → `AnimationPlayer`.

enum Component {
	POSITION = 1,
	VISUAL = 20,
	BODY = 21,
	ANIMATION = 22,
}

func get_tags() -> Array[int]:
	return []

func get_components() -> Dictionary[int, ECSComponent.Type]:
	return {
		Component.POSITION: ECSComponent.Type.PACKED_VECTOR3,
		Component.VISUAL: ECSComponent.Type.NODE3D,
		Component.BODY: ECSComponent.Type.RIGID_BODY_3D,
		Component.ANIMATION: ECSComponent.Type.ANIMATION_PLAYER,
	}
