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

func _packed_from_array(component_ids: Array[int]) -> PackedInt64Array:
	return PackedInt64Array(component_ids)

## Внешний API: Array[int], PackedInt64Array создаётся внутри.
func create_entity(component_ids: Array[int]) -> int:
	return create_entity_packed(_packed_from_array(component_ids))

func create_entity_packed(component_ids: PackedInt64Array) -> int:
	# Генерируем временный отрицательный ID для отслеживания
	var temp_id: int = _next_temp_id
	_next_temp_id -= 1
	var entity_ids: PackedInt64Array = PackedInt64Array([temp_id])
	var command: Command = Command.new(CommandType.CREATE_ENTITY, component_ids, entity_ids)
	_commands.append(command)
	return temp_id

## Внешний API: Array[int], PackedInt64Array создаётся внутри.
func create_entities(count: int, component_ids: Array[int]) -> PackedInt64Array:
	return create_entities_packed(count, _packed_from_array(component_ids))

func create_entities_packed(count: int, component_ids: PackedInt64Array) -> PackedInt64Array:
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

## Внешний API: Array[int], PackedInt64Array создаётся внутри.
func destroy_entities(entity_ids: Array[int]) -> void:
	destroy_entities_packed(_packed_from_array(entity_ids))

func destroy_entities_packed(entity_ids: PackedInt64Array) -> void:
	if entity_ids.is_empty():
		return
	var command: Command = Command.new(CommandType.DESTROY_ENTITIES, PackedInt64Array(), entity_ids)
	_commands.append(command)

func execute() -> void:
	if _ecs_manager == null:
		return

	_temp_id_to_real_id.clear()
	var commands: Array[Command] = _coalesce_commands()
	for command: Command in commands:
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

func _component_op_key(entity_id: int, component_id: int) -> String:
	return "%d:%d" % [entity_id, component_id]

func _coalesce_commands() -> Array[Command]:
	if _commands.is_empty():
		return []
	var cancelled_temps: Dictionary[int, bool] = _find_cancelled_temp_entities()
	var filtered: Array[Command] = _filter_commands(cancelled_temps)
	filtered = _coalesce_component_ops(filtered)
	return _merge_destroy_entity_commands(filtered)

func _find_cancelled_temp_entities() -> Dictionary[int, bool]:
	var seen_create: Dictionary[int, bool] = {}
	var cancelled: Dictionary[int, bool] = {}
	for command: Command in _commands:
		match command.type:
			CommandType.CREATE_ENTITY:
				if !command.entity_ids.is_empty():
					seen_create[command.entity_ids[0]] = true
			CommandType.CREATE_ENTITIES:
				for temp_id: int in command.entity_ids:
					seen_create[temp_id] = true
			CommandType.DESTROY_ENTITY:
				if !command.entity_ids.is_empty():
					var entity_id: int = command.entity_ids[0]
					if entity_id < 0 && seen_create.has(entity_id):
						cancelled[entity_id] = true
			CommandType.DESTROY_ENTITIES:
				for entity_id: int in command.entity_ids:
					if entity_id < 0 && seen_create.has(entity_id):
						cancelled[entity_id] = true
	return cancelled

func _is_entity_inactive(entity_id: int, destroyed: Dictionary[int, bool], cancelled_temps: Dictionary[int, bool]) -> bool:
	if destroyed.has(entity_id):
		return true
	if entity_id < 0 && cancelled_temps.has(entity_id):
		return true
	return false

func _filter_commands(cancelled_temps: Dictionary[int, bool]) -> Array[Command]:
	var result: Array[Command] = []
	var destroyed: Dictionary[int, bool] = {}
	for command: Command in _commands:
		match command.type:
			CommandType.CREATE_ENTITY:
				if command.entity_ids.is_empty():
					continue
				var temp_id: int = command.entity_ids[0]
				if temp_id < 0 && cancelled_temps.has(temp_id):
					continue
				result.append(command)
			CommandType.CREATE_ENTITIES:
				var kept_ids: PackedInt64Array = PackedInt64Array()
				for temp_id: int in command.entity_ids:
					if temp_id >= 0 || !cancelled_temps.has(temp_id):
						kept_ids.append(temp_id)
				if kept_ids.is_empty():
					continue
				result.append(Command.new(CommandType.CREATE_ENTITIES, command.component_ids, kept_ids, kept_ids.size()))
			CommandType.ADD_COMPONENT, CommandType.REMOVE_COMPONENT:
				if command.entity_ids.is_empty() || command.component_ids.is_empty():
					continue
				var entity_id: int = command.entity_ids[0]
				if _is_entity_inactive(entity_id, destroyed, cancelled_temps):
					continue
				result.append(command)
			CommandType.DESTROY_ENTITY:
				if command.entity_ids.is_empty():
					continue
				var entity_id: int = command.entity_ids[0]
				if entity_id < 0 && cancelled_temps.has(entity_id):
					continue
				if destroyed.has(entity_id):
					continue
				destroyed[entity_id] = true
				result.append(command)
			CommandType.DESTROY_ENTITIES:
				var kept: PackedInt64Array = PackedInt64Array()
				for entity_id: int in command.entity_ids:
					if entity_id < 0 && cancelled_temps.has(entity_id):
						continue
					if destroyed.has(entity_id):
						continue
					destroyed[entity_id] = true
					kept.append(entity_id)
				if kept.is_empty():
					continue
				result.append(Command.new(CommandType.DESTROY_ENTITIES, PackedInt64Array(), kept))
	return result

func _coalesce_component_ops(commands: Array[Command]) -> Array[Command]:
	var result: Array[Command] = []
	var pending: Dictionary = {}  ## String -> Command
	var removed: Dictionary = {}  ## Command -> bool (set отменённых)
	for command: Command in commands:
		if command.type != CommandType.ADD_COMPONENT && command.type != CommandType.REMOVE_COMPONENT:
			result.append(command)
			continue
		var entity_id: int = command.entity_ids[0]
		var component_id: int = command.component_ids[0]
		var key: String = _component_op_key(entity_id, component_id)
		if pending.has(key):
			var prev_command: Command = pending[key]
			var is_opposite: bool = (
				(prev_command.type == CommandType.ADD_COMPONENT && command.type == CommandType.REMOVE_COMPONENT)
				|| (prev_command.type == CommandType.REMOVE_COMPONENT && command.type == CommandType.ADD_COMPONENT)
			)
			if is_opposite:
				removed[prev_command] = true
				pending.erase(key)
				continue
		pending[key] = command
		result.append(command)
	var coalesced: Array[Command] = []
	for command: Command in result:
		if !removed.has(command):
			coalesced.append(command)
	return coalesced

func _merge_destroy_entity_commands(commands: Array[Command]) -> Array[Command]:
	var result: Array[Command] = []
	var pending_destroys: PackedInt64Array = PackedInt64Array()
	for command: Command in commands:
		if command.type == CommandType.DESTROY_ENTITY:
			pending_destroys.append(command.entity_ids[0])
			continue
		if !pending_destroys.is_empty():
			result.append(Command.new(CommandType.DESTROY_ENTITIES, PackedInt64Array(), pending_destroys.duplicate()))
			pending_destroys = PackedInt64Array()
		result.append(command)
	if !pending_destroys.is_empty():
		result.append(Command.new(CommandType.DESTROY_ENTITIES, PackedInt64Array(), pending_destroys.duplicate()))
	return result

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
	for i in range(mini(real_entity_ids.size(), command.entity_ids.size())):
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
		_ecs_manager.destroy_entities_packed(real_entity_ids)
