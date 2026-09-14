extends RefCounted
class_name ECSComponent

## Тип хранилища компонента. Собственный enum вместо Variant.Type:
## различает Object-подтипы (Node, Node2D, Resource, …), которые в Variant.Type
## все равны TYPE_OBJECT, и позволяет хранить value-типы без Packed*Array
## в типизированных Array[T].
##
## Порядок групп соответствует списку кодогенерации (editor/ecs_code_gen.gd).
enum Type {
	# packed-буферы (Packed*Array)
	PACKED_BYTE,
	PACKED_INT64,
	PACKED_INT32,
	PACKED_FLOAT64,
	PACKED_FLOAT32,
	PACKED_VECTOR2,
	PACKED_VECTOR3,
	PACKED_VECTOR4,
	PACKED_COLOR,
	PACKED_STRING,

	# примитивы, буфер Array[T]
	BOOL,
	INT,
	FLOAT,

	# built-in value-типы, буфер Array[T]
	AABB,
	RECT2,
	BASIS,
	PLANE,
	TRANSFORM2D,
	TRANSFORM3D,

	QUATERNION,
	VECTOR2,
	VECTOR2I,
	VECTOR3I,
	VECTOR3,
	VECTOR4I,
	VECTOR4,
	COLOR,

	# строковые value-типы, буфер Array[T]
	STRINGNAME,
	STRING,
	NODEPATH,

	# прочие value-типы, буфер Array[T]
	RID,

	# reference-типы, буфер Array[T], default null
	RESOURCE,
	PACKED_SCENE,

	NODE,
	NODE2D,
	NODE3D,

	# generic Object (untyped Array), default null
	OBJECT,
	REFCOUNTED,
}

## snake_case-слаг для папок/файлов сгенерированных компонентов.
## Граница слова — только camelCase (нижний→верхний); цифры остаются в слове:
## "PackedVector4" → "packed_vector4", "Node2D" → "node2d", "StringName" → "string_name".
static func file_slug(part_name: String) -> String:
	var slug: String = ""
	for i in range(part_name.length()):
		var code: int = part_name.unicode_at(i)
		var prev_code: int = part_name.unicode_at(i - 1) if i > 0 else 0
		var is_upper: bool = code >= 65 and code <= 90
		var prev_is_lower: bool = prev_code >= 97 and prev_code <= 122
		if is_upper and prev_is_lower:
			slug += "_"
		slug += part_name.substr(i, 1).to_lower()
	return slug
