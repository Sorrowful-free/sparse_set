class_name ECSCommandBuffer extends RefCounted

enum CommandType {
	CREATE_ENTITY,
	CREATE_ENTITIES,
	ADD_COMPONENT,
	REMOVE_COMPONENT,
	DESTROY_ENTITY,
	DESTROY_ENTITIES
}

class Command:
	var type: CommandType
	var component_ids: PackedInt64Array
	var entity_ids: PackedInt64Array  # Для массовых операций
	var count: int  # Количество сущностей для создания
	
	func _init(cmd_type: CommandType, c_ids: PackedInt64Array = PackedInt64Array(), e_ids: PackedInt64Array = PackedInt64Array(), cnt: int = 0) -> void:
		type = cmd_type
		component_ids = c_ids
		entity_ids = e_ids
		count = cnt

var _ecs_manager: ECSManager
var _commands: Array[Command] = []
var _temp_id_to_real_id: Dictionary[int, int] = {}  # Маппинг временных ID на реальные
var _next_temp_id: int = -1  # Счетчик для генерации уникальных временных ID

func _init(ecs_manager: ECSManager) -> void:
	_ecs_manager = ecs_manager

func create_entity(component_ids: PackedInt64Array) -> int:
	# Генерируем временный отрицательный ID для отслеживания
	var temp_id: int = _next_temp_id
	_next_temp_id -= 1
	var entity_ids: PackedInt64Array = PackedInt64Array([temp_id])
	var command: Command = Command.new(CommandType.CREATE_ENTITY, component_ids, entity_ids)
	_commands.append(command)
	return temp_id

func create_entities(count: int, component_ids: PackedInt64Array) -> PackedInt64Array:
	# Генерируем временные отрицательные ID для отслеживания
	var temp_ids: PackedInt64Array = PackedInt64Array()
	var base_temp_id: int = _next_temp_id
	
	for i in range(count):
		temp_ids.append(base_temp_id - i)
	
	_next_temp_id = base_temp_id - count
	
	var command: Command = Command.new(CommandType.CREATE_ENTITIES, component_ids, temp_ids, count)
	_commands.append(command)
	return temp_ids

func add_component(entity_id: int, component_id: int) -> void:
	var entity_ids: PackedInt64Array = PackedInt64Array([entity_id])
	var component_ids: PackedInt64Array = PackedInt64Array([component_id])
	var command: Command = Command.new(CommandType.ADD_COMPONENT, component_ids, entity_ids)
	_commands.append(command)

func remove_component(entity_id: int, component_id: int) -> void:
	var entity_ids: PackedInt64Array = PackedInt64Array([entity_id])
	var component_ids: PackedInt64Array = PackedInt64Array([component_id])
	var command: Command = Command.new(CommandType.REMOVE_COMPONENT, component_ids, entity_ids)
	_commands.append(command)

func destroy_entity(entity_id: int) -> void:
	var entity_ids: PackedInt64Array = PackedInt64Array([entity_id])
	var command: Command = Command.new(CommandType.DESTROY_ENTITY, PackedInt64Array(), entity_ids)
	_commands.append(command)

func destroy_entities(entity_ids: PackedInt64Array) -> void:
	if entity_ids.is_empty():
		return
	var command: Command = Command.new(CommandType.DESTROY_ENTITIES, PackedInt64Array(), entity_ids)
	_commands.append(command)

func execute() -> void:
	if _ecs_manager == null:
		return
	
	_temp_id_to_real_id.clear()
	
	# Затем выполняем остальные команды, заменяя временные ID на реальные
	for command: Command in _commands:
		match command.type:
			CommandType.CREATE_ENTITY:
				_execute_create_entity(command)
			CommandType.CREATE_ENTITIES:
				_execute_create_entities(command)
			CommandType.ADD_COMPONENT:
				_execute_add_component(command)
			CommandType.REMOVE_COMPONENT:
				_execute_remove_component(command)
			CommandType.DESTROY_ENTITY:
				_execute_destroy_entity(command)
			CommandType.DESTROY_ENTITIES:
				_execute_destroy_entities(command)
	
	clear()

func clear() -> void:
	_commands.clear()
	_temp_id_to_real_id.clear()
	_next_temp_id = -1

func _get_real_entity_id(entity_id: int) -> int:
	# Если это временный ID, заменяем на реальный
	if entity_id < 0 && _temp_id_to_real_id.has(entity_id):
		return _temp_id_to_real_id[entity_id]
	return entity_id

func _execute_create_entity(command: Command) -> void:
	if _ecs_manager == null:
		return
	
	var real_entity_id: int = _ecs_manager.create_entity_packed(command.component_ids)
	
	# Сохраняем маппинг временного ID на реальный
	if command.entity_ids.size() > 0:
		var temp_id: int = command.entity_ids[0]
		if temp_id < 0:
			_temp_id_to_real_id[temp_id] = real_entity_id

func _execute_create_entities(command: Command) -> void:
	if _ecs_manager == null:
		return
	
	var real_entity_ids: PackedInt64Array = _ecs_manager.create_entities_packed(command.count, command.component_ids)
	
	# Сохраняем маппинг временных ID на реальные
	for i in range(min(real_entity_ids.size(), command.entity_ids.size())):
		var temp_id: int = command.entity_ids[i]
		if temp_id < 0:
			_temp_id_to_real_id[temp_id] = real_entity_ids[i]

func _execute_add_component(command: Command) -> void:
	if _ecs_manager == null:
		return
	
	if command.entity_ids.is_empty() || command.component_ids.is_empty():
		return
	
	var real_entity_id: int = _get_real_entity_id(command.entity_ids[0])
	if real_entity_id == 0 || !_ecs_manager.is_alive(real_entity_id):
		return  # Сущность не существует
	
	_ecs_manager.add_component(real_entity_id, command.component_ids[0])

func _execute_remove_component(command: Command) -> void:
	if _ecs_manager == null:
		return
	
	if command.entity_ids.is_empty() || command.component_ids.is_empty():
		return
	
	var real_entity_id: int = _get_real_entity_id(command.entity_ids[0])
	if real_entity_id == 0 || !_ecs_manager.is_alive(real_entity_id):
		return  # Сущность не существует
	
	_ecs_manager.remove_component(real_entity_id, command.component_ids[0])

func _execute_destroy_entity(command: Command) -> void:
	if _ecs_manager == null:
		return
	
	if command.entity_ids.is_empty():
		return
	
	var real_entity_id: int = _get_real_entity_id(command.entity_ids[0])
	if real_entity_id == 0 || !_ecs_manager.is_alive(real_entity_id):
		return  # Сущность не существует
	
	_ecs_manager.destroy_entity(real_entity_id)

func _execute_destroy_entities(command: Command) -> void:
	if _ecs_manager == null:
		return
	
	if command.entity_ids.is_empty():
		return
	
	# Заменяем временные ID на реальные
	var real_entity_ids: PackedInt64Array = PackedInt64Array()
	for entity_id in command.entity_ids:
		var real_entity_id: int = _get_real_entity_id(entity_id)
		if real_entity_id != 0 && _ecs_manager.is_alive(real_entity_id):
			real_entity_ids.append(real_entity_id)
	
	# Удаляем все сущности одним вызовом (оптимизировано)
	if !real_entity_ids.is_empty():
		_ecs_manager.destroy_entities(real_entity_ids)
