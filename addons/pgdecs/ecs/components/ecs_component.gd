extends RefCounted
class_name ECSComponent

## Тип хранилища компонента. Собственный enum вместо Variant.Type:
## различает Object-подтипы (Node, Node2D, Resource, …), которые в Variant.Type
## все равны TYPE_OBJECT, и позволяет хранить value-типы без Packed*Array
## в типизированных Array[T].
enum Type {
	# packed-буферы (Packed*Array)
	PACKED_BYTE,
	PACKED_INT32,
	PACKED_INT64,
	PACKED_FLOAT32,
	PACKED_FLOAT64,
	PACKED_VECTOR2,
	PACKED_VECTOR3,
	PACKED_VECTOR4,
	PACKED_COLOR,
	PACKED_STRING,

	# built-in value-типы, буфер Array[T]
	AABB,
	RECT2,
	QUATERNION,
	BASIS,
	TRANSFORM2D,
	TRANSFORM3D,
	VECTOR2I,
	VECTOR3I,
	VECTOR4I,

	# reference-типы, буфер Array[T], default null
	OBJECT,
	NODE,
	NODE2D,
	NODE3D,
	RESOURCE,
	PACKED_SCENE,
	REF_COUNTED,
}
