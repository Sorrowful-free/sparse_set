extends SceneTree

const TEMPLATES_PATH: String = "res://addons/pgdecs/ecs/editor/templates"
const COMPONENTS_PATH: String = "res://addons/pgdecs/ecs/components/generated"
const COMPONENTS: Array[Dictionary] = [
	{"value_type": "int", "default_value": "0", "packed_type": "PackedByteArray", "part_name": "Byte"},
	{"value_type": "int", "default_value": "0", "packed_type": "PackedInt64Array", "part_name": "Int64"},
	{"value_type": "int", "default_value": "0", "packed_type": "PackedInt32Array", "part_name": "Int32"},
	{"value_type": "float", "default_value": "0.0", "packed_type": "PackedFloat64Array", "part_name": "Float64"},
	{"value_type": "float", "default_value": "0.0", "packed_type": "PackedFloat32Array", "part_name": "Float32"},
	{"value_type": "Vector2", "default_value": "Vector2.ZERO", "packed_type": "PackedVector2Array", "part_name": "Vector2"},
	{"value_type": "Vector3", "default_value": "Vector3.ZERO", "packed_type": "PackedVector3Array", "part_name": "Vector3"},
	{"value_type": "Vector4", "default_value": "Vector4.ZERO", "packed_type": "PackedVector4Array", "part_name": "Vector4"},
	{"value_type": "Color", "default_value": "Color.BLACK", "packed_type": "PackedColorArray", "part_name": "Color"},
	{"value_type": "String", "default_value": '""', "packed_type": "PackedStringArray", "part_name": "String"}
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
		var lower_part_name: String = part_name.to_lower()
		var folder_name: String = lower_part_name
		var component_array_file_name: String = "ecs_component_" + lower_part_name + "_array.gd"
		var component_array_chunk_file_name: String = "ecs_component_" + lower_part_name + "_chunk_array.gd"
		var component_array_type: String = "ECSComponent" + part_name + "Array"
		var component_array_chunk_type: String = "ECSComponent" + part_name + "ArrayChunk"
		var value_type: String = component["value_type"] as String
		var default_value: String = component["default_value"] as String
		var packed_type: String = component["packed_type"] as String

		var component_folder_name: String = ProjectSettings.globalize_path(COMPONENTS_PATH + "/" + folder_name)
		DirAccess.make_dir_recursive_absolute(component_folder_name)

		var component_array_path: String = ProjectSettings.globalize_path(component_folder_name + "/" + component_array_file_name)
		var component_array_chunk_path: String = ProjectSettings.globalize_path(component_folder_name + "/" + component_array_chunk_file_name)

		var component_text: String = component_template_text \
		.replace("{component_array_type}", component_array_type) \
		.replace("{component_array_chunk_type}", component_array_chunk_type) \
		.replace("{value_type}", value_type) \
		.replace("{default_value}", default_value) \
		.replace("{packed_type}", packed_type)

		var component_chunk_text: String = component_chunk_template_text \
		.replace("{component_array_chunk_type}", component_array_chunk_type) \
		.replace("{value_type}", value_type) \
		.replace("{default_value}", default_value) \
		.replace("{packed_type}", packed_type)

		var component_file: FileAccess = FileAccess.open(component_array_path, FileAccess.WRITE)
		component_file.store_string(component_text)
		component_file.close()

		var component_chunk_file: FileAccess = FileAccess.open(component_array_chunk_path, FileAccess.WRITE)
		component_chunk_file.store_string(component_chunk_text)
		component_chunk_file.close()
		print("generated: ", component_array_type)
