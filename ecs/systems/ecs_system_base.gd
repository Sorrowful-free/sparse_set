class_name ECSSystemBase extends RefCounted

var _ecs_manager: ECSManager
var _command_buffer: ECSCommandBuffer

func _init(ecs_manager: ECSManager) -> void:
	_ecs_manager = ecs_manager
	_command_buffer = ECSCommandBuffer.new(ecs_manager)

## Переопределяйте в наследниках. Вызывается раннером каждый кадр/тик.
func update(_delta: float) -> void:
	pass

## Буфер команд для отложенного создания/удаления сущностей и компонентов.
func get_command_buffer() -> ECSCommandBuffer:
	return _command_buffer

## Доступ к ECS для запросов и get_component_array.
func get_ecs_manager() -> ECSManager:
	return _ecs_manager