class_name ECSSystemRunGroups

## Рекомендованные имена run_group (не entity tags).

const SIMULATION := &"simulation"
const NETWORK := &"network"
const FRAME := &"frame"
const DEFAULT := SIMULATION

static func default_group_configs() -> Array[ECSSystemGroupConfig]:
	var simulation := ECSSystemGroupConfig.new()
	simulation.group = SIMULATION
	simulation.process_hook = ECSSystemGroupConfig.ProcessHook.PHYSICS_PROCESS
	simulation.hz = 0.0
	simulation.execution_order = 0

	var network := ECSSystemGroupConfig.new()
	network.group = NETWORK
	network.process_hook = ECSSystemGroupConfig.ProcessHook.PROCESS
	network.hz = 20.0
	network.execution_order = 0

	var frame := ECSSystemGroupConfig.new()
	frame.group = FRAME
	frame.process_hook = ECSSystemGroupConfig.ProcessHook.PROCESS
	frame.hz = 0.0
	frame.execution_order = 10

	return [simulation, network, frame]
