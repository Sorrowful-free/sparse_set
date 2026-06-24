extends SceneTree

func _init() -> void:
	OS.delay_msec(3000)
	print("ECSComponentRegistryConfig=", ClassDB.class_exists("ECSComponentRegistryConfig"))
	print("ECSWorldProfile=", ClassDB.class_exists("ECSWorldProfile"))
	print("ECSVisualHost=", ClassDB.class_exists("ECSVisualHost"))
	var s = load("res://addons/pgdecs/ecs/tests/unit/ecs_world_profile_test.gd")
	print("profile_test=", s)
	quit()
