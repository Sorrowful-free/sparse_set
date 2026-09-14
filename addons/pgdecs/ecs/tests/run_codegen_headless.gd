extends SceneTree

const TEMPLATES_PATH: String = "res://addons/pgdecs/ecs/editor/templates"
const COMPONENTS_PATH: String = "res://addons/pgdecs/ecs/components/generated"
## Порядок строк = порядок групп в ECSComponent.Type (канонический).
const COMPONENTS: Array[Dictionary] = [
	# packed-буферы (Packed*Array)
	{"value_type": "int", "default_value": "0", "array_type": "PackedByteArray", "part_name": "PackedByte"},
	{"value_type": "int", "default_value": "0", "array_type": "PackedInt64Array", "part_name": "PackedInt64"},
	{"value_type": "int", "default_value": "0", "array_type": "PackedInt32Array", "part_name": "PackedInt32"},
	{"value_type": "float", "default_value": "0.0", "array_type": "PackedFloat64Array", "part_name": "PackedFloat64"},
	{"value_type": "float", "default_value": "0.0", "array_type": "PackedFloat32Array", "part_name": "PackedFloat32"},
	{"value_type": "String", "default_value": '""', "array_type": "PackedStringArray", "part_name": "PackedString"},
	{"value_type": "Color", "default_value": "Color.BLACK", "array_type": "PackedColorArray", "part_name": "PackedColor"},
	{"value_type": "Vector2", "default_value": "Vector2.ZERO", "array_type": "PackedVector2Array", "part_name": "PackedVector2"},
	{"value_type": "Vector3", "default_value": "Vector3.ZERO", "array_type": "PackedVector3Array", "part_name": "PackedVector3"},
	{"value_type": "Vector4", "default_value": "Vector4.ZERO", "array_type": "PackedVector4Array", "part_name": "PackedVector4"},

	# примитивы
	{"value_type": "bool", "default_value": "false", "array_type": "Array[bool]", "part_name": "Bool"},
	{"value_type": "int", "default_value": "0", "array_type": "Array[int]", "part_name": "Int"},
	{"value_type": "float", "default_value": "0.0", "array_type": "Array[float]", "part_name": "Float"},

	# built-in value-типы
	{"value_type": "AABB", "default_value": "AABB()", "array_type": "Array[AABB]", "part_name": "AABB"},
	{"value_type": "Rect2", "default_value": "Rect2()", "array_type": "Array[Rect2]", "part_name": "Rect2"},
	{"value_type": "Rect2i", "default_value": "Rect2i()", "array_type": "Array[Rect2i]", "part_name": "Rect2i"},
	{"value_type": "Basis", "default_value": "Basis.IDENTITY", "array_type": "Array[Basis]", "part_name": "Basis"},
	{"value_type": "Plane", "default_value": "Plane()", "array_type": "Array[Plane]", "part_name": "Plane"},
	{"value_type": "Projection", "default_value": "Projection()", "array_type": "Array[Projection]", "part_name": "Projection"},
	{"value_type": "Transform2D", "default_value": "Transform2D.IDENTITY", "array_type": "Array[Transform2D]", "part_name": "Transform2D"},
	{"value_type": "Transform3D", "default_value": "Transform3D.IDENTITY", "array_type": "Array[Transform3D]", "part_name": "Transform3D"},
	{"value_type": "Quaternion", "default_value": "Quaternion.IDENTITY", "array_type": "Array[Quaternion]", "part_name": "Quaternion"},
	{"value_type": "Vector2", "default_value": "Vector2.ZERO", "array_type": "Array[Vector2]", "part_name": "Vector2"},
	{"value_type": "Vector2i", "default_value": "Vector2i.ZERO", "array_type": "Array[Vector2i]", "part_name": "Vector2i"},
	{"value_type": "Vector3", "default_value": "Vector3.ZERO", "array_type": "Array[Vector3]", "part_name": "Vector3"},
	{"value_type": "Vector3i", "default_value": "Vector3i.ZERO", "array_type": "Array[Vector3i]", "part_name": "Vector3i"},
	{"value_type": "Vector4", "default_value": "Vector4.ZERO", "array_type": "Array[Vector4]", "part_name": "Vector4"},
	{"value_type": "Vector4i", "default_value": "Vector4i.ZERO", "array_type": "Array[Vector4i]", "part_name": "Vector4i"},
	{"value_type": "Color", "default_value": "Color.BLACK", "array_type": "Array[Color]", "part_name": "Color"},
	{"value_type": "StringName", "default_value": '&""', "array_type": "Array[StringName]", "part_name": "StringName"},
	{"value_type": "String", "default_value": '""', "array_type": "Array[String]", "part_name": "String"},
	{"value_type": "NodePath", "default_value": '^""', "array_type": "Array[NodePath]", "part_name": "NodePath"},
	{"value_type": "RID", "default_value": "RID()", "array_type": "Array[RID]", "part_name": "RID"},

	# reference-типы (default null)
	{"value_type": "Resource", "default_value": "null", "array_type": "Array[Resource]", "part_name": "Resource"},
	{"value_type": "PackedScene", "default_value": "null", "array_type": "Array[PackedScene]", "part_name": "PackedScene"},
	{"value_type": "Node", "default_value": "null", "array_type": "Array[Node]", "part_name": "Node"},
	{"value_type": "Node2D", "default_value": "null", "array_type": "Array[Node2D]", "part_name": "Node2D"},
	{"value_type": "Node3D", "default_value": "null", "array_type": "Array[Node3D]", "part_name": "Node3D"},
	{"value_type": "Object", "default_value": "null", "array_type": "Array", "part_name": "Object"},
	{"value_type": "RefCounted", "default_value": "null", "array_type": "Array[RefCounted]", "part_name": "RefCounted"},

	# частые подтипы (анимация / рендер / физика / навигация / прочее)
	{"value_type": "Tween", "default_value": "null", "array_type": "Array[Tween]", "part_name": "Tween"},
	{"value_type": "AnimationPlayer", "default_value": "null", "array_type": "Array[AnimationPlayer]", "part_name": "AnimationPlayer"},
	{"value_type": "AnimationTree", "default_value": "null", "array_type": "Array[AnimationTree]", "part_name": "AnimationTree"},
	{"value_type": "MeshInstance2D", "default_value": "null", "array_type": "Array[MeshInstance2D]", "part_name": "MeshInstance2D"},
	{"value_type": "MeshInstance3D", "default_value": "null", "array_type": "Array[MeshInstance3D]", "part_name": "MeshInstance3D"},
	{"value_type": "MultiMeshInstance2D", "default_value": "null", "array_type": "Array[MultiMeshInstance2D]", "part_name": "MultiMeshInstance2D"},
	{"value_type": "MultiMeshInstance3D", "default_value": "null", "array_type": "Array[MultiMeshInstance3D]", "part_name": "MultiMeshInstance3D"},
	{"value_type": "RigidBody2D", "default_value": "null", "array_type": "Array[RigidBody2D]", "part_name": "RigidBody2D"},
	{"value_type": "RigidBody3D", "default_value": "null", "array_type": "Array[RigidBody3D]", "part_name": "RigidBody3D"},
	{"value_type": "CharacterBody2D", "default_value": "null", "array_type": "Array[CharacterBody2D]", "part_name": "CharacterBody2D"},
	{"value_type": "CharacterBody3D", "default_value": "null", "array_type": "Array[CharacterBody3D]", "part_name": "CharacterBody3D"},
	{"value_type": "StaticBody2D", "default_value": "null", "array_type": "Array[StaticBody2D]", "part_name": "StaticBody2D"},
	{"value_type": "StaticBody3D", "default_value": "null", "array_type": "Array[StaticBody3D]", "part_name": "StaticBody3D"},
	{"value_type": "Area2D", "default_value": "null", "array_type": "Array[Area2D]", "part_name": "Area2D"},
	{"value_type": "Area3D", "default_value": "null", "array_type": "Array[Area3D]", "part_name": "Area3D"},
	{"value_type": "CollisionShape2D", "default_value": "null", "array_type": "Array[CollisionShape2D]", "part_name": "CollisionShape2D"},
	{"value_type": "CollisionShape3D", "default_value": "null", "array_type": "Array[CollisionShape3D]", "part_name": "CollisionShape3D"},
	{"value_type": "CollisionPolygon2D", "default_value": "null", "array_type": "Array[CollisionPolygon2D]", "part_name": "CollisionPolygon2D"},
	{"value_type": "CollisionPolygon3D", "default_value": "null", "array_type": "Array[CollisionPolygon3D]", "part_name": "CollisionPolygon3D"},
	{"value_type": "Shape2D", "default_value": "null", "array_type": "Array[Shape2D]", "part_name": "Shape2D"},
	{"value_type": "Shape3D", "default_value": "null", "array_type": "Array[Shape3D]", "part_name": "Shape3D"},
	{"value_type": "NavigationAgent2D", "default_value": "null", "array_type": "Array[NavigationAgent2D]", "part_name": "NavigationAgent2D"},
	{"value_type": "NavigationAgent3D", "default_value": "null", "array_type": "Array[NavigationAgent3D]", "part_name": "NavigationAgent3D"},
	{"value_type": "Timer", "default_value": "null", "array_type": "Array[Timer]", "part_name": "Timer"}
]

func _initialize() -> void:
	_run_codegen()
	quit(0)

func _run_codegen() -> void:
	var component_template_path: String = ProjectSettings.globalize_path(TEMPLATES_PATH + "/{component_type_array}.gdt")
	var component_chunk_template_path: String = ProjectSettings.globalize_path(TEMPLATES_PATH + "/{component_type_array_chunk}.gdt")
	var component_template_text: String = FileAccess.open(component_template_path, FileAccess.READ).get_as_text()
	var component_chunk_template_text: String = FileAccess.open(component_chunk_template_path, FileAccess.READ).get_as_text()
	for component: Dictionary in COMPONENTS:
		var part_name: String = component["part_name"] as String
		var file_slug: String = ECSComponent.file_slug(part_name)
		var folder_name: String = file_slug
		var component_array_file_name: String = "ecs_component_" + file_slug + "_array.gd"
		var component_array_chunk_file_name: String = "ecs_component_" + file_slug + "_chunk_array.gd"
		var component_array_type: String = "ECSComponent" + part_name + "Array"
		var component_array_chunk_type: String = "ECSComponent" + part_name + "ArrayChunk"
		var value_type: String = component["value_type"] as String
		var default_value: String = component["default_value"] as String
		var array_type: String = component["array_type"] as String
		var buffer_init: String = "[]" if array_type.begins_with("Array[") else array_type + "()"

		var component_folder_name: String = ProjectSettings.globalize_path(COMPONENTS_PATH + "/" + folder_name)
		DirAccess.make_dir_recursive_absolute(component_folder_name)

		var component_array_path: String = ProjectSettings.globalize_path(component_folder_name + "/" + component_array_file_name)
		var component_array_chunk_path: String = ProjectSettings.globalize_path(component_folder_name + "/" + component_array_chunk_file_name)

		var component_text: String = component_template_text \
		.replace("{component_array_type}", component_array_type) \
		.replace("{component_array_chunk_type}", component_array_chunk_type) \
		.replace("{value_type}", value_type) \
		.replace("{default_value}", default_value) \
		.replace("{array_type}", array_type)

		var component_chunk_text: String = component_chunk_template_text \
		.replace("{component_array_chunk_type}", component_array_chunk_type) \
		.replace("{value_type}", value_type) \
		.replace("{default_value}", default_value) \
		.replace("{array_type}", array_type) \
		.replace("{buffer_init}", buffer_init)

		var component_file: FileAccess = FileAccess.open(component_array_path, FileAccess.WRITE)
		component_file.store_string(component_text)
		component_file.close()

		var component_chunk_file: FileAccess = FileAccess.open(component_array_chunk_path, FileAccess.WRITE)
		component_chunk_file.store_string(component_chunk_text)
		component_chunk_file.close()
		print("generated: ", component_array_type)
