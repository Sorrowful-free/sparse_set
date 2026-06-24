extends GutTest
class_name ECSComponentFactoryTest

func test_known_types() -> void:
	assert_not_null(ECSComponentFactory.create_component(TYPE_PACKED_BYTE_ARRAY))
	assert_not_null(ECSComponentFactory.create_component(TYPE_PACKED_INT32_ARRAY))
	assert_not_null(ECSComponentFactory.create_component(TYPE_PACKED_INT64_ARRAY))
	assert_not_null(ECSComponentFactory.create_component(TYPE_PACKED_FLOAT32_ARRAY))
	assert_not_null(ECSComponentFactory.create_component(TYPE_PACKED_FLOAT64_ARRAY))
	assert_not_null(ECSComponentFactory.create_component(TYPE_PACKED_VECTOR2_ARRAY))
	assert_not_null(ECSComponentFactory.create_component(TYPE_PACKED_VECTOR3_ARRAY))
	assert_not_null(ECSComponentFactory.create_component(TYPE_PACKED_VECTOR4_ARRAY))
	assert_not_null(ECSComponentFactory.create_component(TYPE_PACKED_COLOR_ARRAY))

func test_unknown_type_returns_null() -> void:
	assert_null(ECSComponentFactory.create_component(TYPE_STRING))
	assert_push_error("unsupported component type")
