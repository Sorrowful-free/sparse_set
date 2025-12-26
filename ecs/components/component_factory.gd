extends RefCounted
class_name ComponentFactory

static func create_component(component_type: Variant.Type, component_capacity: int, chunk_capacity: int) -> ComponentBase:
	match component_type:
		TYPE_PACKED_BYTE_ARRAY:
			return ComponentByte.new(component_capacity, chunk_capacity)
		TYPE_PACKED_INT32_ARRAY:
			return ComponentInt32.new(component_capacity, chunk_capacity)
		TYPE_PACKED_INT64_ARRAY:
			return ComponentInt64.new(component_capacity, chunk_capacity)
		TYPE_PACKED_FLOAT32_ARRAY:
			return ComponentFloat32.new(component_capacity, chunk_capacity)
		TYPE_PACKED_FLOAT64_ARRAY:
			return ComponentFloat64.new(component_capacity, chunk_capacity)
		TYPE_PACKED_VECTOR2_ARRAY:
			return ComponentVector2.new(component_capacity, chunk_capacity)
		TYPE_PACKED_VECTOR3_ARRAY:
			return ComponentVector3.new(component_capacity, chunk_capacity)
		TYPE_PACKED_VECTOR4_ARRAY:
			return ComponentVector4.new(component_capacity, chunk_capacity)
		TYPE_PACKED_COLOR_ARRAY:
			return ComponentColor.new(component_capacity, chunk_capacity)
		_:
			return null
