extends Node
class_name ECSWorld

## Мир ECS: менеджер, раннер систем и scheduler по profile.
## Запуск через [@export var profile] или [method apply_profile] (один раз).

@export var profile: ECSWorldProfile
@export var scene_world_blueprint: ECSSceneWorldBlueprint

var _ecs_manager: ECSManager
var _system_runner: ECSSystemRunner
var _system_scheduler: ECSSystemScheduler
var _profile_applied: bool = false
var _schedule_installed: bool = false

func _ready() -> void:
	_init_runtime()
	set_physics_process(true)
	if profile != null:
		apply_profile(profile)
	elif OS.is_debug_build():
		push_warning("ECSWorld: profile is not set")

func _physics_process(delta: float) -> void:
	if _schedule_installed:
		_system_scheduler.tick_physics(delta)

func _process(delta: float) -> void:
	if _schedule_installed:
		_system_scheduler.tick_process(delta)
	elif _system_runner != null:
		_system_runner.run(delta)
	if _system_runner != null:
		_system_runner.flush_manual_command_buffers()
	if _ecs_manager != null and _ecs_manager.auto_gc_archetypes:
		_ecs_manager.flush_archetype_gc_if_pending()

func _init_runtime() -> void:
	if _ecs_manager == null:
		_ecs_manager = ECSManager.new()
	if _system_runner == null:
		_system_runner = ECSSystemRunner.new()
	if _system_scheduler == null:
		_system_scheduler = ECSSystemScheduler.new()

func is_profile_applied() -> bool:
	return _profile_applied

func install_system_schedule(configs: Array[ECSSystemGroupConfig]) -> void:
	_init_runtime()
	_system_scheduler.install(configs, _system_runner)
	_schedule_installed = true

func apply_profile(world_profile: ECSWorldProfile) -> void:
	if _profile_applied:
		if OS.is_debug_build():
			push_warning("ECSWorld.apply_profile: profile already applied, ignoring")
		return
	_init_runtime()
	profile = world_profile
	_warn_component_registry_strategy(world_profile)
	world_profile.register_components_to_world(self)
	_build_scene_world()
	world_profile.apply_systems_to_world(self)
	_profile_applied = true

func _build_scene_world() -> void:
	if scene_world_blueprint == null:
		return
	if scene_world_blueprint.get_parent() != self:
		push_error("ECSWorld: scene_world_blueprint must be a child of this ECSWorld")
		return
	scene_world_blueprint.build_world(_ecs_manager)

func _warn_component_registry_strategy(world_profile: ECSWorldProfile) -> void:
	if not OS.is_debug_build():
		return
	var strategy: ECSComponentRegistryStrategy = world_profile.component_registry_strategy
	if strategy == null:
		push_warning("ECSWorldProfile: component_registry_strategy is not set")
	elif not strategy.enabled:
		push_warning("ECSWorldProfile: component_registry_strategy is disabled")

func get_ecs_manager() -> ECSManager:
	return _ecs_manager

func get_system_runner() -> ECSSystemRunner:
	return _system_runner

func get_system_scheduler() -> ECSSystemScheduler:
	return _system_scheduler

func run_system_group(group: StringName, delta: float) -> void:
	if _system_scheduler != null:
		_system_scheduler.fire_group(group, delta)

func reset_world() -> void:
	if _ecs_manager != null:
		_ecs_manager.reset()
	if _system_runner != null:
		_system_runner.clear()
	_schedule_installed = false
	_profile_applied = false
