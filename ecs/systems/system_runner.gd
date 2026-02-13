class_name SystemRunner extends RefCounted

## Вызывает update() у всех систем по порядку, затем execute() у каждого command buffer.
## Использование: add_system(system); run(delta) каждый кадр.

var _systems: Array[SystemBase] = []

func add_system(system: SystemBase) -> void:
	_systems.append(system)

func remove_system(system: SystemBase) -> void:
	_systems.erase(system)

func get_systems() -> Array[SystemBase]:
	return _systems.duplicate()

## Обновляет все системы, затем выполняет все command buffer'ы.
func run(delta: float) -> void:
	for system in _systems:
		system.update(delta)
	for system in _systems:
		system.get_command_buffer().execute()

func clear() -> void:
	_systems.clear()
