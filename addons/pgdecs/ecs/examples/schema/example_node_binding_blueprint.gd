class_name ExampleNodeBindingBlueprint extends ECSEntityBlueprint

## Абстрактный пример: blueprint описывает **и данные, и создание нод**.
## Ноды не перечисляются в [method build_component_ids] — их component id добавляются
## в архетип автоматически из [method build_node_bindings].
##
## Порядок (main thread, вне `process_chunk`):
## 1. `var buf := ECSCommandBuffer.new(ecs)`
## 2. `blueprint.spawn_batch_bound(buf, count, host)` — сущности + по инстансу ноды на каждую
## 3. `buf.execute()` — сущности создаются уже с нодами в компонентах
##
## Сцены абстрактные: корень каждой совпадает с типом компонента
## (`VISUAL` → `Node3D`, `BODY` → `RigidBody3D`, `ANIMATION` → `AnimationPlayer`).
## Если сцена не задана, соответствующий binding — no-op: компонент не попадает в архетип.

@export var visual_scene: PackedScene
@export var body_scene: PackedScene
@export var animation_scene: PackedScene

@export var initial_position: Vector3 = Vector3.ZERO

func build_component_ids() -> PackedInt64Array:
	return PackedInt64Array([
		ExampleNodeComponentRegistryStrategy.Component.POSITION,
	])

func build_default_values() -> Dictionary:
	return {
		ExampleNodeComponentRegistryStrategy.Component.POSITION: initial_position,
	}

func build_node_bindings() -> Array[ECSBlueprintNodeBinding]:
	return [
		ECSBlueprintNodeBinding.of(ExampleNodeComponentRegistryStrategy.Component.VISUAL, visual_scene),
		ECSBlueprintNodeBinding.of(ExampleNodeComponentRegistryStrategy.Component.BODY, body_scene),
		ECSBlueprintNodeBinding.of(ExampleNodeComponentRegistryStrategy.Component.ANIMATION, animation_scene),
	]
