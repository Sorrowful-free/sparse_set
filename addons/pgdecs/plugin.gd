@tool
extends EditorPlugin

const CODEGEN_SCRIPT := preload("res://addons/pgdecs/ecs/editor/ecs_code_gen.gd")

func _enter_tree() -> void:
	add_tool_menu_item("PGDECS: Regenerate Components", _run_codegen)

func _exit_tree() -> void:
	remove_tool_menu_item("PGDECS: Regenerate Components")

func _run_codegen() -> void:
	var codegen: ECSCodeGen = CODEGEN_SCRIPT.new()
	codegen._run()
