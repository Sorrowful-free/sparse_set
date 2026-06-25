class_name ECSSystemGroupConfig extends Resource

## Настройка фазы ECS: имя группы, Godot hook, частота и порядок внутри hook.

enum ProcessHook { PHYSICS_PROCESS, PROCESS, MANUAL }

@export var group: StringName = &"simulation"
@export var enabled: bool = true
@export var process_hook: ProcessHook = ProcessHook.PHYSICS_PROCESS
## 0 = каждый tick соответствующего hook; иначе fixed-step по hz.
@export var hz: float = 0.0
## Меньше — раньше внутри одного hook (например network перед frame).
@export var execution_order: int = 0
