extends SceneTree

## Headless entry: делегирует в GUT CLI (см. .gutconfig.json).

func _init() -> void:
	var VersionConversion = load("res://addons/gut/version_conversion.gd")
	if VersionConversion.error_if_not_all_classes_imported():
		quit(0)
		return

	load("res://addons/gut/gut_loader.gd")

	var max_iter := 20
	var iter := 0
	while Engine.get_main_loop() == null and iter < max_iter:
		await create_timer(0.01).timeout
		iter += 1

	if Engine.get_main_loop() == null:
		push_error("Main loop did not start in time.")
		quit(1)
		return

	var cli: Node = load("res://addons/gut/cli/gut_cli.gd").new()
	get_root().add_child(cli)
	cli.main()
