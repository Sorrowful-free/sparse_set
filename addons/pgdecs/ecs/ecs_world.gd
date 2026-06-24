extends Node
class_name ECSWorld

## Мир ECS: менеджер, раннер систем, опциональный visual registry.
## Запуск через [@export var profile] или [method apply_profile].

@export var profile: ECSWorldProfile

var _ecs_manager: ECSManager
var _system_runner: ECSSystemRunner
var _visual_registry: ECSVisualRegistry

func _ready() -> void:
	_init_runtime()
	if profile != null:
		apply_profile(profile)
	elif OS.is_debug_build():
		push_warning("ECSWorld: profile is not set")

func _process(delta: float) -> void:
	_system_runner.run(delta)

func _init_runtime() -> void:
	if _ecs_manager == null:
		_ecs_manager = ECSManager.new()
	if _system_runner == null:
		_system_runner = ECSSystemRunner.new()

func apply_profile(world_profile: ECSWorldProfile) -> void:
	_init_runtime()
	profile = world_profile
	world_profile.apply_to_world(self)

func get_ecs_manager() -> ECSManager:
	return _ecs_manager

func get_system_runner() -> ECSSystemRunner:
	return _system_runner

func get_visual_registry() -> ECSVisualRegistry:
	return _visual_registry

func set_visual_registry(registry: ECSVisualRegistry) -> void:
	_visual_registry = registry
