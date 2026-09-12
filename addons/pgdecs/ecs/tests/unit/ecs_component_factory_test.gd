extends GutTest
class_name ECSComponentFactoryTest

func test_known_types() -> void:
	assert_not_null(ECSComponentFactory.create_component(ECSComponent.Type.PACKED_BYTE))
	assert_not_null(ECSComponentFactory.create_component(ECSComponent.Type.PACKED_INT32))
	assert_not_null(ECSComponentFactory.create_component(ECSComponent.Type.PACKED_INT64))
	assert_not_null(ECSComponentFactory.create_component(ECSComponent.Type.PACKED_FLOAT32))
	assert_not_null(ECSComponentFactory.create_component(ECSComponent.Type.PACKED_FLOAT64))
	assert_not_null(ECSComponentFactory.create_component(ECSComponent.Type.PACKED_VECTOR2))
	assert_not_null(ECSComponentFactory.create_component(ECSComponent.Type.PACKED_VECTOR3))
	assert_not_null(ECSComponentFactory.create_component(ECSComponent.Type.PACKED_VECTOR4))
	assert_not_null(ECSComponentFactory.create_component(ECSComponent.Type.PACKED_COLOR))
	assert_not_null(ECSComponentFactory.create_component(ECSComponent.Type.PACKED_STRING))
	assert_not_null(ECSComponentFactory.create_component(ECSComponent.Type.AABB))
	assert_not_null(ECSComponentFactory.create_component(ECSComponent.Type.RECT2))
	assert_not_null(ECSComponentFactory.create_component(ECSComponent.Type.QUATERNION))
	assert_not_null(ECSComponentFactory.create_component(ECSComponent.Type.BASIS))
	assert_not_null(ECSComponentFactory.create_component(ECSComponent.Type.TRANSFORM2D))
	assert_not_null(ECSComponentFactory.create_component(ECSComponent.Type.TRANSFORM3D))
	assert_not_null(ECSComponentFactory.create_component(ECSComponent.Type.VECTOR2I))
	assert_not_null(ECSComponentFactory.create_component(ECSComponent.Type.VECTOR3I))
	assert_not_null(ECSComponentFactory.create_component(ECSComponent.Type.VECTOR4I))
	assert_not_null(ECSComponentFactory.create_component(ECSComponent.Type.OBJECT))
	assert_not_null(ECSComponentFactory.create_component(ECSComponent.Type.NODE))
	assert_not_null(ECSComponentFactory.create_component(ECSComponent.Type.NODE2D))
	assert_not_null(ECSComponentFactory.create_component(ECSComponent.Type.NODE3D))
	assert_not_null(ECSComponentFactory.create_component(ECSComponent.Type.RESOURCE))
	assert_not_null(ECSComponentFactory.create_component(ECSComponent.Type.PACKED_SCENE))
	assert_not_null(ECSComponentFactory.create_component(ECSComponent.Type.REF_COUNTED))

func test_storage_classes() -> void:
	assert_true(ECSComponentFactory.create_component(ECSComponent.Type.AABB) is ECSComponentAABBArray)
	assert_true(ECSComponentFactory.create_component(ECSComponent.Type.TRANSFORM3D) is ECSComponentTransform3DArray)
	assert_true(ECSComponentFactory.create_component(ECSComponent.Type.VECTOR2I) is ECSComponentVector2iArray)
	assert_true(ECSComponentFactory.create_component(ECSComponent.Type.OBJECT) is ECSComponentObjectArray)
	assert_true(ECSComponentFactory.create_component(ECSComponent.Type.NODE) is ECSComponentNodeArray)
	assert_true(ECSComponentFactory.create_component(ECSComponent.Type.NODE2D) is ECSComponentNode2DArray)
	assert_true(ECSComponentFactory.create_component(ECSComponent.Type.RESOURCE) is ECSComponentResourceArray)

func test_invalid_type_returns_null() -> void:
	assert_null(ECSComponentFactory.create_component(999 as ECSComponent.Type))
	assert_push_error("unsupported component type")
