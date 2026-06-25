class_name ECSSystemScheduler extends RefCounted

## Маршрутизирует run_group по ECSSystemGroupConfig: hook, hz, execution_order.

var _runner: ECSSystemRunner = null
var _physics_groups: Array[StringName] = []
var _process_groups: Array[StringName] = []
var _manual_groups: Dictionary = {}
var _tickers: Dictionary = {}

func install(configs: Array[ECSSystemGroupConfig], runner: ECSSystemRunner) -> void:
	_runner = runner
	_physics_groups.clear()
	_process_groups.clear()
	_manual_groups.clear()
	_tickers.clear()

	var enabled_configs: Array[ECSSystemGroupConfig] = []
	for config: ECSSystemGroupConfig in configs:
		if config == null or not config.enabled:
			continue
		enabled_configs.append(config)

	enabled_configs.sort_custom(func(a: ECSSystemGroupConfig, b: ECSSystemGroupConfig) -> bool:
		return a.execution_order < b.execution_order
	)

	var group_order: Array[StringName] = []
	for config: ECSSystemGroupConfig in enabled_configs:
		group_order.append(config.group)
		match config.process_hook:
			ECSSystemGroupConfig.ProcessHook.PHYSICS_PROCESS:
				_physics_groups.append(config.group)
			ECSSystemGroupConfig.ProcessHook.PROCESS:
				_process_groups.append(config.group)
			ECSSystemGroupConfig.ProcessHook.MANUAL:
				_manual_groups[config.group] = config
		if config.hz > 0.0:
			_tickers[config.group] = ECSSystemGroupTicker.new(config.group, config.hz, runner)

	runner.set_group_order(group_order)

func tick_physics(delta: float) -> void:
	for group: StringName in _physics_groups:
		_tick_group(group, delta)

func tick_process(delta: float) -> void:
	for group: StringName in _process_groups:
		_tick_group(group, delta)

func fire_group(group: StringName, delta: float) -> void:
	if _runner == null:
		return
	if not _manual_groups.has(group):
		if OS.is_debug_build():
			push_warning("ECSSystemScheduler.fire_group: group '%s' is not MANUAL or not installed" % group)
		_runner.run_group(group, delta)
		return
	_tick_group(group, delta)

func set_group_hz(group: StringName, hz: float) -> void:
	if _tickers.has(group):
		(_tickers[group] as ECSSystemGroupTicker).set_hz(hz)

func get_physics_groups() -> Array[StringName]:
	return _physics_groups.duplicate()

func get_process_groups() -> Array[StringName]:
	return _process_groups.duplicate()

func get_manual_groups() -> Array[StringName]:
	var keys: Array[StringName] = []
	for key: Variant in _manual_groups.keys():
		keys.append(key as StringName)
	return keys

func _tick_group(group: StringName, delta: float) -> void:
	if _tickers.has(group):
		(_tickers[group] as ECSSystemGroupTicker).tick(delta)
	elif _runner != null:
		_runner.run_group(group, delta)
