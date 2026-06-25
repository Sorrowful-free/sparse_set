extends Node
class_name ECSBridgeHost

## Якорь bridge-сцены под [ECSWorld]. [member slots] задаёт именованные ноды для backends.
@export var slots: Dictionary[StringName, NodePath] = {}

var _resolved: Dictionary[StringName, Node] = {}
var _dirty: bool = true

func _ready() -> void:
	child_order_changed.connect(_mark_dirty)
	tree_entered.connect(_mark_dirty)
	_mark_dirty()

func _mark_dirty() -> void:
	_dirty = true

func refresh_slots() -> void:
	_resolved.clear()
	for slot: StringName in slots:
		var path: NodePath = slots[slot]
		if path.is_empty():
			_resolved[slot] = self
		else:
			_resolved[slot] = get_node_or_null(path)
	_dirty = false

func get_slot(slot: StringName) -> Node:
	if _dirty:
		refresh_slots()
	return _resolved.get(slot, null)

func require_slot(slot: StringName) -> Node:
	var node: Node = get_slot(slot)
	if node == null:
		push_error("ECSBridgeHost: missing slot '%s'" % slot)
	return node
