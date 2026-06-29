extends ECSWorldProfile
class_name ExampleIntentWorldProfile

## Пример profile: intent pipeline в run_group=frame (порядок strategies = порядок систем).
## Назначьте [member services] в inspector (subresource ExampleEcsServices + ECSNodeRegistry).

@export var services: ExampleEcsServices

func _init() -> void:
	system_groups = ECSSystemRunGroups.default_group_configs()
	component_registry_strategy = ExampleIntentComponentRegistryStrategy.new()
	_setup_intent_strategies()

func _setup_intent_strategies() -> void:
	var bind := ExampleBindIntentStrategy.new()
	bind.run_group = ECSSystemRunGroups.FRAME
	bind.services = services

	var sync := ExampleRegistrySyncStrategy.new()
	sync.run_group = ECSSystemRunGroups.FRAME
	sync.services = services

	var release := ExampleReleaseIntentStrategy.new()
	release.run_group = ECSSystemRunGroups.FRAME
	release.services = services

	var sweep := ExampleDestroySweepStrategy.new()
	sweep.run_group = ECSSystemRunGroups.FRAME

	system_strategies = [bind, sync, release, sweep]
