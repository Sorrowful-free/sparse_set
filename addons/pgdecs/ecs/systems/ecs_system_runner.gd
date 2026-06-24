class_name ECSSystemRunner extends RefCounted

## Вызывает update() у всех систем по порядку, затем execute() у каждого command buffer.
## При auto_gc_archetypes у менеджера — flush_archetype_gc() один раз в конце run().
## Использование: add_system(system); run(delta) каждый кадр.

var _systems: Array[ECSSystemBase] = []
var _ecs_manager: ECSManager = null

func add_system(system: ECSSystemBase) -> void:
	_systems.append(system)
	if _ecs_manager == null:
		_ecs_manager = system.get_ecs_manager()

func remove_system(system: ECSSystemBase) -> void:
	_systems.erase(system)

func get_systems() -> Array[ECSSystemBase]:
	return _systems.duplicate()

func get_ecs_manager() -> ECSManager:
	return _ecs_manager

## Обновляет все системы, затем выполняет все command buffer'ы, затем отложенный GC архетипов.
func run(delta: float) -> void:
	for system in _systems:
		system.update(delta)
	for system in _systems:
		system.get_command_buffer().execute()
	if _ecs_manager != null && _ecs_manager.auto_gc_archetypes:
		_ecs_manager.flush_archetype_gc_if_pending()

func clear() -> void:
	_systems.clear()
	_ecs_manager = null
