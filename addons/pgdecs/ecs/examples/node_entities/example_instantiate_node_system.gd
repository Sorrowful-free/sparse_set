class_name ExampleInstantiateNodeSystem
extends ECSSystemBase

## Инстанцирует `PACKED_SCENE`, затем заменяет этот компонент на `VISUAL` (Node3D).
## Структурные изменения выполняются отложенным command buffer после process_system.

var _root_node: Node
var _query: ECSQuery


func _init(ecs_manager: ECSManager, root_node: Node) -> void:
	_root_node = root_node
	super(ecs_manager)
	_query = (
		ECSQueryBuilder
		. new()
		. with_component(ExampleInstantiateNodeComponentRegistryStrategy.Component.PACKED_SCENE)
		. build(ecs_manager)
	)


func process_system(_delta: float) -> void:
	var ecs: ECSManager = get_ecs_manager()
	var scene_components: ECSComponentPackedSceneArray = (
		ecs.get_component_array(
			ExampleInstantiateNodeComponentRegistryStrategy.Component.PACKED_SCENE
		)
		as ECSComponentPackedSceneArray
	)
	if scene_components == null:
		return

	var position_components: ECSComponentPackedVector3Array = (
		ecs.get_component_array(ExampleInstantiateNodeComponentRegistryStrategy.Component.POSITION)
		as ECSComponentPackedVector3Array
	)
	var command_buffer: ECSCommandBuffer = get_command_buffer()
	for entity_id: int in _query.get_entity_ids():
		var scene: PackedScene = scene_components.get_component(entity_id)
		if scene == null:
			continue

		var instance: Node = scene.instantiate()
		var node: Node3D = instance as Node3D
		if node == null:
			if instance != null:
				instance.free()
			push_error("ExampleInstantiateNodeSystem: корень сцены не Node3D")
			continue

		if position_components != null:
			node.position = position_components.get_component(entity_id)
		if _root_node != null:
			_root_node.add_child(node)

		command_buffer.remove_component(
			entity_id, ExampleInstantiateNodeComponentRegistryStrategy.Component.PACKED_SCENE
		)
		command_buffer.add_component(
			entity_id, ExampleInstantiateNodeComponentRegistryStrategy.Component.VISUAL, node
		)
