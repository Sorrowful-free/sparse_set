class_name ECSBlueprintNodeBinding extends Resource

## Описание привязки ноды к сущности: какой reference-компонент получает инстанс [PackedScene].
## Часть [ECSEntityBlueprint]: blueprint описывает не только набор component id, но и то,
## как из сцены создаётся нода и в какой компонент она кладётся.
##
## Ядро **не знает** тип ноды: контракт — корень сцены совпадает с типом хранилища компонента
## (напр. `ECSComponent.Type.NODE3D` ожидает `Node3D`, `ANIMATION_PLAYER` — `AnimationPlayer`).

@export var component_id: int = 0
@export var scene: PackedScene

static func of(component_id: int, scene: PackedScene) -> ECSBlueprintNodeBinding:
	var binding: ECSBlueprintNodeBinding = ECSBlueprintNodeBinding.new()
	binding.component_id = component_id
	binding.scene = scene
	return binding

## Binding без сцены — no-op: компонент не попадает в архетип и нода не создаётся.
## Так «нет ноды» остаётся выразимым через членство, а не через `null`-значение.
func is_active() -> bool:
	return scene != null and component_id != 0

## Новый инстанс на каждый вызов (шарения между сущностями нет).
## [param host] — если задан, нода добавляется к нему в дерево сцены.
## Без сцены (binding неактивен) возвращает `null` без ошибки.
func instantiate(host: Node = null) -> Node:
	if scene == null:
		return null
	var node: Node = scene.instantiate()
	if node == null:
		push_error("ECSBlueprintNodeBinding: failed to instantiate (component_id=%d)" % component_id)
		return null
	if host != null:
		host.add_child(node)
	return node
