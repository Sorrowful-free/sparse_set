class_name ECSSystemRunner extends RefCounted

## Запускает системы по run_group; после каждой системы — flush command buffer (PER_SYSTEM по умолчанию).
## GC архетипов — ответственность ECSWorld (конец кадра), не раннера.

var _systems_by_group: Dictionary = {}
var _group_order: Array[StringName] = []
var _ecs_manager: ECSManager = null

func set_group_order(order: Array[StringName]) -> void:
	_group_order = order.duplicate()

func get_group_order() -> Array[StringName]:
	return _group_order.duplicate()

func add_system(system: ECSSystemBase, group: StringName = system.run_group) -> void:
	if not _systems_by_group.has(group):
		_systems_by_group[group] = [] as Array[ECSSystemBase]
	(_systems_by_group[group] as Array).append(system)
	if _ecs_manager == null:
		_ecs_manager = system.get_ecs_manager()
	if not _group_order.has(group):
		_group_order.append(group)

func remove_system(system: ECSSystemBase) -> void:
	for group_key: Variant in _systems_by_group.keys():
		var systems: Array = _systems_by_group[group_key]
		systems.erase(system)
		if systems.is_empty():
			_systems_by_group.erase(group_key)

func get_systems() -> Array[ECSSystemBase]:
	var result: Array[ECSSystemBase] = []
	for group: StringName in _resolve_group_order():
		if not _systems_by_group.has(group):
			continue
		for system: ECSSystemBase in _systems_by_group[group]:
			result.append(system)
	return result

func get_groups() -> Array[StringName]:
	return _resolve_group_order()

func get_systems_in_group(group: StringName) -> Array[ECSSystemBase]:
	if not _systems_by_group.has(group):
		return []
	var copy: Array[ECSSystemBase] = []
	for system: ECSSystemBase in _systems_by_group[group]:
		copy.append(system)
	return copy

func get_ecs_manager() -> ECSManager:
	return _ecs_manager

func run_group(group: StringName, delta: float) -> void:
	if not _systems_by_group.has(group):
		return
	var systems: Array = _systems_by_group[group]
	for system: ECSSystemBase in systems:
		if not system.enabled:
			continue
		system.update(delta)
		_flush_after_system(system)
	_flush_per_group_buffers(systems)

func run(delta: float) -> void:
	for group: StringName in _resolve_group_order():
		run_group(group, delta)

func flush_manual_command_buffers() -> void:
	for group: StringName in _systems_by_group.keys():
		_flush_manual_buffers(_systems_by_group[group])

func clear() -> void:
	_systems_by_group.clear()
	_group_order.clear()
	_ecs_manager = null

func _resolve_group_order() -> Array[StringName]:
	if not _group_order.is_empty():
		return _group_order
	var keys: Array[StringName] = []
	for key: Variant in _systems_by_group.keys():
		keys.append(key as StringName)
	keys.sort()
	return keys

func _flush_after_system(system: ECSSystemBase) -> void:
	if system.command_buffer_flush_mode != ECSSystemBase.CommandBufferFlushMode.PER_SYSTEM:
		return
	var buf: ECSCommandBuffer = system.get_command_buffer()
	if buf.has_pending_commands():
		buf.execute()

func _flush_per_group_buffers(systems: Array) -> void:
	for system: ECSSystemBase in systems:
		if system.command_buffer_flush_mode != ECSSystemBase.CommandBufferFlushMode.PER_GROUP:
			continue
		var buf: ECSCommandBuffer = system.get_command_buffer()
		if buf.has_pending_commands():
			buf.execute()

func _flush_manual_buffers(systems: Array) -> void:
	for system: ECSSystemBase in systems:
		if system.command_buffer_flush_mode != ECSSystemBase.CommandBufferFlushMode.MANUAL:
			continue
		var buf: ECSCommandBuffer = system.get_command_buffer()
		if buf.has_pending_commands():
			buf.execute()
