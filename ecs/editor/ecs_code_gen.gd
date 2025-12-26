@tool
extends EditorScript
class_name ECSCodeGen

const templates_path: String = "res://ecs/editor/templates"
const components_path: String = "res://ecs/components/generated"
const components: Array = [
	{"value_type": "int", "default_value": "0", "packed_type": "PackedByteArray", "component_type": "ComponentByte", "component_chunk_type": "ComponentChunkByte", "component_file": "component_byte.gd", "component_chunk_file": "component_chunk_byte.gd", "folder_name": "byte"},
	{"value_type": "int", "default_value": "0", "packed_type": "PackedInt64Array", "component_type": "ComponentInt64", "component_chunk_type": "ComponentChunkInt64", "component_file": "component_int64.gd", "component_chunk_file": "component_chunk_int64.gd", "folder_name": "int64"},
	{"value_type": "int", "default_value": "0", "packed_type": "PackedInt32Array", "component_type": "ComponentInt32", "component_chunk_type": "ComponentChunkInt32", "component_file": "component_int32.gd", "component_chunk_file": "component_chunk_int32.gd", "folder_name": "int32"},
	{"value_type": "float", "default_value": "0.0", "packed_type": "PackedFloat64Array", "component_type": "ComponentFloat64", "component_chunk_type": "ComponentChunkFloat64", "component_file": "component_float64.gd", "component_chunk_file": "component_chunk_float64.gd", "folder_name": "float64"},
	{"value_type": "float", "default_value": "0.0", "packed_type": "PackedFloat32Array", "component_type": "ComponentFloat32", "component_chunk_type": "ComponentChunkFloat32", "component_file": "component_float32.gd", "component_chunk_file": "component_chunk_float32.gd", "folder_name": "float32"},
	{"value_type": "Vector2", "default_value": "Vector2.ZERO", "packed_type": "PackedVector2Array", "component_type": "ComponentVector2", "component_chunk_type": "ComponentChunkVector2", "component_file": "component_vector2.gd", "component_chunk_file": "component_chunk_vector2.gd", "folder_name": "vector2"},
	{"value_type": "Vector3", "default_value": "Vector3.ZERO", "packed_type": "PackedVector3Array", "component_type": "ComponentVector3", "component_chunk_type": "ComponentChunkVector3", "component_file": "component_vector3.gd", "component_chunk_file": "component_chunk_vector3.gd", "folder_name": "vector3"},
	{"value_type": "Vector4", "default_value": "Vector4.ZERO", "packed_type": "PackedVector4Array", "component_type": "ComponentVector4", "component_chunk_type": "ComponentChunkVector4", "component_file": "component_vector4.gd", "component_chunk_file": "component_chunk_vector4.gd", "folder_name": "vector4"},
	{"value_type": "Color", "default_value": "Color.BLACK", "packed_type": "PackedColorArray", "component_type": "ComponentColor", "component_chunk_type": "ComponentChunkColor", "component_file": "component_color.gd", "component_chunk_file": "component_chunk_color.gd", "folder_name": "color"},
]


func _run():
	var component_template_path: String = ProjectSettings.globalize_path(templates_path + "/{component_type}.gdt")
	var component_chunk_template_path: String = ProjectSettings.globalize_path(templates_path + "/{component_chunk_type}.gdt")

	print(component_template_path)
	print(component_chunk_template_path)

	var component_template_text: String = FileAccess.open(component_template_path, FileAccess.READ).get_as_text()
	var component_chunk_template_text: String = FileAccess.open(component_chunk_template_path, FileAccess.READ).get_as_text()
	for component in components:
		var component_folder_name: String = ProjectSettings.globalize_path(components_path + "/" + component["folder_name"])
		DirAccess.make_dir_recursive_absolute(component_folder_name)

		var component_path: String = ProjectSettings.globalize_path(component_folder_name + "/" + component["component_file"])
		var component_chunk_path: String = ProjectSettings.globalize_path(component_folder_name + "/" + component["component_chunk_file"])

		print(component_path)
		print(component_chunk_path)

		var component_text: String = component_template_text.replace("{component_type}", component["component_type"]).replace("{component_chunk_type}", component["component_chunk_type"]).replace("{value_type}", component["value_type"]).replace("{default_value}", component["default_value"]).replace("{packed_type}", component["packed_type"])
		var component_chunk_text: String = component_chunk_template_text.replace("{component_chunk_type}", component["component_chunk_type"]).replace("{value_type}", component["value_type"]).replace("{default_value}", component["default_value"]).replace("{packed_type}", component["packed_type"]).replace("{component_chunk_type}", component["component_chunk_type"])

		var component_file = FileAccess.open(component_path, FileAccess.WRITE)
		component_file.store_string(component_text)
		component_file.close()

		var component_chunk_file = FileAccess.open(component_chunk_path, FileAccess.WRITE)
		component_chunk_file.store_string(component_chunk_text)
		component_chunk_file.close()

		print("Generated component %s" % component["component_type"])
		print("Generated component chunk %s" % component["component_chunk_type"])
