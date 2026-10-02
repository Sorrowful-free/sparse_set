class_name ECSSceneWorldBlueprint extends Node

## Координатор построения ECS-сущностей из явно указанного корня сцены.
## Scene-данные принадлежат marker-узлам; связи дерева не переносятся в ECS.

@export var scene_root: Node

## Создаёт сущности всех marker-узлов в одном bootstrap execute и возвращает их число.
func build_world(ecs: ECSManager) -> int:
	if ecs == null or scene_root == null:
		return 0

	var markers: Array[ECSSceneEntityBlueprint] = []
	_collect_markers(scene_root, markers)
	if markers.is_empty():
		return 0

	var buf: ECSCommandBuffer = ECSCommandBuffer.new(ecs)
	var spawned_count: int = 0
	for marker: ECSSceneEntityBlueprint in markers:
		marker.spawn_from_scene(buf)
		spawned_count += 1

	if buf.has_pending_commands():
		buf.execute()
	return spawned_count

func _collect_markers(node: Node, markers: Array[ECSSceneEntityBlueprint]) -> void:
	if node is ECSSceneEntityBlueprint:
		markers.append(node as ECSSceneEntityBlueprint)
	for child: Node in node.get_children():
		_collect_markers(child, markers)
