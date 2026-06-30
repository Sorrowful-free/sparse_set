extends ECSWorldProfile
class_name ExampleIntentWorldProfile

## Пример profile: intent pipeline в run_group=frame (порядок strategies = порядок систем).
## [member dependencies] на profile — wiring для inspector (игровой слой); ядро ECSWorldProfile этого не объявляет.
## Назначьте subresource ExampleEcsDependencies + ECSNodeRegistry в inspector.

@export var dependencies: ExampleEcsDependencies

func _init() -> void:
	system_groups = ECSSystemRunGroups.default_group_configs()
	component_registry_strategy = ExampleIntentComponentRegistryStrategy.new()
	_setup_intent_strategies()

func _setup_intent_strategies() -> void:
	var bind := ExampleBindIntentStrategy.new()
	bind.run_group = ECSSystemRunGroups.FRAME
	bind.dependencies = dependencies

	var sync := ExampleRegistrySyncStrategy.new()
	sync.run_group = ECSSystemRunGroups.FRAME
	sync.dependencies = dependencies

	var release := ExampleReleaseIntentStrategy.new()
	release.run_group = ECSSystemRunGroups.FRAME
	release.dependencies = dependencies

	var sweep := ExampleDestroySweepStrategy.new()
	sweep.run_group = ECSSystemRunGroups.FRAME

	system_strategies = [bind, sync, release, sweep]
