extends Node
class_name ECSWorld

## Абстрактный мир ECS: держит менеджер сущностей и раннер систем.
## Отправная точка для запуска ECS — переопределите _setup_components() и _setup_systems() в наследниках.

var _ecs_manager: ECSManager
var _system_runner: ECSSystemRunner

func _ready() -> void:
	_ecs_manager = ECSManager.new()
	_system_runner = ECSSystemRunner.new()
	_setup_components()
	_setup_systems()

func _process(delta: float) -> void:
	_system_runner.run(delta)

## Переопределите: регистрация компонентов через _ecs_manager.register_component().
func _setup_components() -> void:
	pass

## Переопределите: добавление систем через _system_runner.add_system(). Системы создавайте с get_ecs_manager().
func _setup_systems() -> void:
	pass

func get_ecs_manager() -> ECSManager:
	return _ecs_manager

func get_system_runner() -> ECSSystemRunner:
	return _system_runner
