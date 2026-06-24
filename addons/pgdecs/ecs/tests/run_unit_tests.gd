@tool
extends EditorScript
class_name RunUnitTests

## Запуск PGDECS unit tests через GUT из редактора.

func _run() -> void:
	var godot_bin: String = OS.get_executable_path()
	var project_path: String = ProjectSettings.globalize_path("res://")
	var args: PackedStringArray = [
		"--path", project_path,
		"--headless",
		"--script", "res://addons/gut/gut_cmdln.gd",
		"-gconfig=res://.gutconfig.json",
		"-gexit",
	]
	var output: Array = []
	var exit_code: int = OS.execute(godot_bin, args, output, true, false)
	for line in output:
		print(line)
	if exit_code != 0:
		push_error("GUT unit tests failed (exit %d)" % exit_code)
