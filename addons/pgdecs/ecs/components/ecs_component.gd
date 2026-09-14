extends RefCounted
class_name ECSComponent

## Тип хранилища компонента для [ECSComponentFactory] и [method ECSManager.register_component].
##
## Собственный enum вместо [enum Variant.Type]:
## - Object-подтипы (Node, Node2D, Resource, …) в `Variant.Type` неразличимы — все `TYPE_OBJECT`;
## - value-типы без `Packed*Array` хранятся в типизированных `Array[T]` (Rect2i, Projection, …);
## - список типов расширяется аддоном, а не версией Godot.
##
## Буфер чанка:
## - `PACKED_*` → `Packed*Array`: плотный SoA, скаляр на slot — лучший вариант для hot path;
## - остальные → типизированный `Array[T]`: значение value-типа либо ссылка (default `null`);
## - `OBJECT` → untyped `Array`, API типизирован `Object` (принимает любой Object).
##
## Reference-типы (`OBJECT`, `RESOURCE`, `NODE`, …) хранят ссылку: `get_*` возвращает тот же
## объект, `set_*` не копирует. Нужна независимая копия — `duplicate(true)`.
## Подробности и таблица буферов: OBJECT_COMPONENTS.md.
##
## Порядок групп — канонический: список кодогенерации (editor/ecs_code_gen.gd) идёт в том же порядке.
enum Type {
	# --- packed-буферы (Packed*Array) ---
	PACKED_BYTE,
	PACKED_INT64,
	PACKED_INT32,
	PACKED_FLOAT64,
	PACKED_FLOAT32,
	PACKED_STRING,
	PACKED_COLOR,
	PACKED_VECTOR2,
	PACKED_VECTOR3,
	PACKED_VECTOR4,

	# --- примитивы (Array[T]) ---
	BOOL,
	INT,
	FLOAT,

	# --- built-in value-типы (Array[T], value-семантика: get возвращает копию) ---
	AABB,
	RECT2,
	RECT2I,
	BASIS,
	PLANE,
	PROJECTION,
	TRANSFORM2D,
	TRANSFORM3D,
	QUATERNION,
	# вектора и цвет
	VECTOR2,
	VECTOR2I,
	VECTOR3,
	VECTOR3I,
	VECTOR4,
	VECTOR4I,
	COLOR,
	# строки и пути
	STRINGNAME,
	STRING,
	NODEPATH,
	# прочие built-in
	RID,

	# --- reference-типы (Array[T], default null; значение — ссылка, не копия) ---
	# ресурсы
	RESOURCE,
	PACKED_SCENE,
	# ноды (NODE принимает любые подклассы Node — отдельные типы ниже нужны только
	# для типизированного доступа без `as`-каста)
	NODE,
	NODE2D,
	NODE3D,
	# generic-фоллбэки
	OBJECT,      # untyped Array, API типизирован Object — любой Object
	REFCOUNTED,

	# --- частые подтипы: `Array[T]` вместо `Array[Node]` (типизация, не новые возможности) ---
	# анимация
	TWEEN,             # RefCounted, не Node
	ANIMATION_PLAYER,  # Node
	ANIMATION_TREE,    # Node (AnimationMixer)
	# рендер
	MESH_INSTANCE_2D,
	MESH_INSTANCE_3D,
	MULTI_MESH_INSTANCE_2D,  # инстансинг тысяч объектов
	MULTI_MESH_INSTANCE_3D,
	# физика
	RIGID_BODY_2D,
	RIGID_BODY_3D,
	CHARACTER_BODY_2D,
	CHARACTER_BODY_3D,
	STATIC_BODY_2D,
	STATIC_BODY_3D,
	AREA_2D,
	AREA_3D,
	# шейпы: CollisionShape*/CollisionPolygon* — Node; Shape2D/3D — Resource-база
	COLLISION_SHAPE_2D,
	COLLISION_SHAPE_3D,
	COLLISION_POLYGON_2D,
	COLLISION_POLYGON_3D,
	SHAPE_2D,
	SHAPE_3D,
	# навигация
	NAVIGATION_AGENT_2D,
	NAVIGATION_AGENT_3D,
	# прочее
	TIMER,
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
