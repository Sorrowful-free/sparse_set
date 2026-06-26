extends RefCounted
class_name ECSComponentFactory

static func create_component(component_type: Variant.Type) -> ECSComponentBaseArray:
	match component_type:
		TYPE_PACKED_BYTE_ARRAY:
			return ECSComponentByteArray.new()
		TYPE_PACKED_INT32_ARRAY:
			return ECSComponentInt32Array.new()
		TYPE_PACKED_INT64_ARRAY:
			return ECSComponentInt64Array.new()
		TYPE_PACKED_FLOAT32_ARRAY:
			return ECSComponentFloat32Array.new()
		TYPE_PACKED_FLOAT64_ARRAY:
			return ECSComponentFloat64Array.new()
		TYPE_PACKED_VECTOR2_ARRAY:
			return ECSComponentVector2Array.new()
		TYPE_PACKED_VECTOR3_ARRAY:
			return ECSComponentVector3Array.new()
		TYPE_PACKED_VECTOR4_ARRAY:
			return ECSComponentVector4Array.new()
		TYPE_PACKED_COLOR_ARRAY:
			return ECSComponentColorArray.new()
		TYPE_PACKED_STRING_ARRAY:
			return ECSComponentStringArray.new()
		_:
			push_error("ECSComponentFactory: unsupported component type %d" % component_type)
			return null
