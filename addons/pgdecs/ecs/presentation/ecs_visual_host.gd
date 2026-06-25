extends Node
class_name ECSVisualHost

## Якорь visual-сцены под [ECSWorld]. [member slots] задаёт именованные ноды для backends.
@export var slots: Dictionary[StringName, NodePath] = {}

var _resolved: Dictionary[StringName, Node] = {}

func _ready() -> void:
	_resolve_slots()

func _resolve_slots() -> void:
	_resolved.clear()
	for slot: StringName in slots:
		var path: NodePath = slots[slot]
		if path.is_empty():
			_resolved[slot] = self
		else:
			_resolved[slot] = get_node_or_null(path)

func get_slot(slot: StringName) -> Node:
	return _resolved.get(slot, null)

func require_slot(slot: StringName) -> Node:
	var node: Node = get_slot(slot)
	if node == null:
		push_error("ECSVisualHost: missing slot '%s'" % slot)
	return node
