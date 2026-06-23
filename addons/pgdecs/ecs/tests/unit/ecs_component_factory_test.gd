extends RefCounted
class_name ECSComponentFactoryTest

func test_known_types(runner: ECSTestRunner) -> void:
	runner.assert_not_null(ECSComponentFactory.create_component(TYPE_PACKED_BYTE_ARRAY))
	runner.assert_not_null(ECSComponentFactory.create_component(TYPE_PACKED_INT32_ARRAY))
	runner.assert_not_null(ECSComponentFactory.create_component(TYPE_PACKED_INT64_ARRAY))
	runner.assert_not_null(ECSComponentFactory.create_component(TYPE_PACKED_FLOAT32_ARRAY))
	runner.assert_not_null(ECSComponentFactory.create_component(TYPE_PACKED_FLOAT64_ARRAY))
	runner.assert_not_null(ECSComponentFactory.create_component(TYPE_PACKED_VECTOR2_ARRAY))
	runner.assert_not_null(ECSComponentFactory.create_component(TYPE_PACKED_VECTOR3_ARRAY))
	runner.assert_not_null(ECSComponentFactory.create_component(TYPE_PACKED_VECTOR4_ARRAY))
	runner.assert_not_null(ECSComponentFactory.create_component(TYPE_PACKED_COLOR_ARRAY))

func test_unknown_type_returns_null(runner: ECSTestRunner) -> void:
	runner.assert_null(ECSComponentFactory.create_component(TYPE_STRING))
