extends Node
class_name ECSWorld

## Мир ECS: менеджер, раннер систем, scheduler по profile, опциональный bridge registry.
## Запуск через [@export var profile] или [method apply_profile] (один раз).

@export var profile: ECSWorldProfile

var _ecs_manager: ECSManager
var _system_runner: ECSSystemRunner
var _system_scheduler: ECSSystemScheduler
var _bridge_registry: ECSBridgeRegistry
var _profile_applied: bool = false
var _schedule_installed: bool = false

func _ready() -> void:
	_init_runtime()
	set_physics_process(true)
	if profile != null:
		apply_profile(profile)
	elif OS.is_debug_build():
		push_warning("ECSWorld: profile is not set")

func _enter_tree() -> void:
	_try_install_deferred_bridge_registry()

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
	world_profile.apply_to_world(self, _find_bridge_host())
	_profile_applied = true

func _warn_component_registry_strategy(world_profile: ECSWorldProfile) -> void:
	if not OS.is_debug_build():
		return
	var strategy: ECSComponentRegistryStrategy = world_profile.component_registry_strategy
	if strategy == null:
		push_warning("ECSWorldProfile: component_registry_strategy is not set")
	elif not strategy.enabled:
		push_warning("ECSWorldProfile: component_registry_strategy is disabled")

func _find_bridge_host() -> ECSBridgeHost:
	for child: Node in get_children():
		if child is ECSBridgeHost:
			return child as ECSBridgeHost
	return null

func _try_install_deferred_bridge_registry() -> void:
	if not _profile_applied or profile == null:
		return
	if _bridge_registry != null:
		return
	if profile.bridge_registry_strategy == null or not profile.bridge_registry_strategy.enabled:
		return
	if profile.bridge_registry_strategy.backend_strategies.is_empty():
		return
	var host: ECSBridgeHost = _find_bridge_host()
	if host == null:
		return
	profile._apply_bridge_registry(self, host)

func get_ecs_manager() -> ECSManager:
	return _ecs_manager

func get_system_runner() -> ECSSystemRunner:
	return _system_runner

func get_system_scheduler() -> ECSSystemScheduler:
	return _system_scheduler

func run_system_group(group: StringName, delta: float) -> void:
	if _system_scheduler != null:
		_system_scheduler.fire_group(group, delta)

func get_bridge_registry() -> ECSBridgeRegistry:
	return _bridge_registry

func set_bridge_registry(registry: ECSBridgeRegistry) -> void:
	_bridge_registry = registry

func reset_world() -> void:
	if _ecs_manager != null:
		_ecs_manager.reset()
	if _system_runner != null:
		_system_runner.clear()
	_bridge_registry = null
	_schedule_installed = false
	_profile_applied = false
