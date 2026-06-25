extends Node
class_name ECSWorld

## Мир ECS: менеджер, раннер систем, опциональный visual registry.
## Запуск через [@export var profile] или [method apply_profile] (один раз).

@export var profile: ECSWorldProfile

var _ecs_manager: ECSManager
var _system_runner: ECSSystemRunner
var _visual_registry: ECSVisualRegistry
var _profile_applied: bool = false

func _ready() -> void:
	_init_runtime()
	if profile != null:
		apply_profile(profile)
	elif OS.is_debug_build():
		push_warning("ECSWorld: profile is not set")

func _enter_tree() -> void:
	_try_install_deferred_visual_registry()

func _process(delta: float) -> void:
	_system_runner.run(delta)
	if _visual_registry != null:
		_visual_registry.sync_all(_ecs_manager, delta)

func _init_runtime() -> void:
	if _ecs_manager == null:
		_ecs_manager = ECSManager.new()
	if _system_runner == null:
		_system_runner = ECSSystemRunner.new()

func is_profile_applied() -> bool:
	return _profile_applied

func apply_profile(world_profile: ECSWorldProfile) -> void:
	if _profile_applied:
		if OS.is_debug_build():
			push_warning("ECSWorld.apply_profile: profile already applied, ignoring")
		return
	_init_runtime()
	profile = world_profile
	_warn_component_registry_strategy(world_profile)
	world_profile.apply_to_world(self, _find_visual_host())
	_profile_applied = true

func _warn_component_registry_strategy(world_profile: ECSWorldProfile) -> void:
	if not OS.is_debug_build():
		return
	var strategy: ECSComponentRegistryStrategy = world_profile.component_registry_strategy
	if strategy == null:
		push_warning("ECSWorldProfile: component_registry_strategy is not set")
	elif not strategy.enabled:
		push_warning("ECSWorldProfile: component_registry_strategy is disabled")

func _find_visual_host() -> ECSVisualHost:
	for child: Node in get_children():
		if child is ECSVisualHost:
			return child as ECSVisualHost
	return null

func _try_install_deferred_visual_registry() -> void:
	if not _profile_applied or profile == null:
		return
	if _visual_registry != null:
		return
	if profile.visual_registry_strategy == null:
		return
	profile.apply_visual_strategy(self, _find_visual_host())

func get_ecs_manager() -> ECSManager:
	return _ecs_manager

func get_system_runner() -> ECSSystemRunner:
	return _system_runner

func get_visual_registry() -> ECSVisualRegistry:
	return _visual_registry

func set_visual_registry(registry: ECSVisualRegistry) -> void:
	_visual_registry = registry

func reset_world() -> void:
	if _ecs_manager != null:
		_ecs_manager.reset()
	if _system_runner != null:
		_system_runner.clear()
	_visual_registry = null
	_profile_applied = false
