extends RefCounted
class_name ComponentFactory

static func create_component(component_type: Variant.Type) -> ComponentBaseArray:
	match component_type:
		TYPE_PACKED_BYTE_ARRAY:
			return ComponentByteArray.new()
		TYPE_PACKED_INT32_ARRAY:
			return ComponentInt32Array.new()
		TYPE_PACKED_INT64_ARRAY:
			return ComponentInt64Array.new()
		TYPE_PACKED_FLOAT32_ARRAY:
			return ComponentFloat32Array.new()
		TYPE_PACKED_FLOAT64_ARRAY:
			return ComponentFloat64Array.new()
		TYPE_PACKED_VECTOR2_ARRAY:
			return ComponentVector2Array.new()
		TYPE_PACKED_VECTOR3_ARRAY:
			return ComponentVector3Array.new()
		TYPE_PACKED_VECTOR4_ARRAY:
			return ComponentVector4Array.new()
		TYPE_PACKED_COLOR_ARRAY:
			return ComponentColorArray.new()
		_:
			return null
