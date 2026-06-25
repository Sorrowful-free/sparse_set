class_name ECSSystemGroupTicker extends RefCounted

## Аккумулятор hz для одной run_group; вызывает runner.run_group при наступлении шага.

var _group: StringName
var _hz: float = 0.0
var _accumulator: float = 0.0
var _runner: ECSSystemRunner = null

func _init(group: StringName, hz: float, runner: ECSSystemRunner) -> void:
	_group = group
	_hz = hz
	_runner = runner

func get_group() -> StringName:
	return _group

func get_hz() -> float:
	return _hz

func set_hz(hz: float) -> void:
	_hz = hz

func tick(delta: float) -> void:
	if _runner == null:
		return
	if _hz <= 0.0:
		_runner.run_group(_group, delta)
		return
	var step: float = 1.0 / _hz
	_accumulator += delta
	while _accumulator >= step:
		_runner.run_group(_group, step)
		_accumulator -= step

func reset() -> void:
	_accumulator = 0.0
