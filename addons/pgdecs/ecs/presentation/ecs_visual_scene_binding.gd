class_name ECSVisualSceneBinding extends Resource

## Именованные слоты сцены: StringName → NodePath относительно [ECSVisualHost].
@export var slots: Dictionary = {}

func resolve(root: Node) -> Dictionary:
	var resolved: Dictionary = {}
	for slot: Variant in slots.keys():
		var path: NodePath = slots[slot]
		if path.is_empty():
			resolved[slot] = root
		else:
			resolved[slot] = root.get_node_or_null(path)
	return resolved
