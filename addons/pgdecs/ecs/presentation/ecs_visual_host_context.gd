class_name ECSVisualHostContext extends RefCounted

var _root: Node
var _slots: Dictionary = {}

func _init(root: Node, binding = null) -> void:
	_root = root
	if binding != null and binding.has_method("resolve"):
		_slots = binding.resolve(root)

static func from_world(world: Node) -> ECSVisualHostContext:
	for child: Node in world.get_children():
		if child is ECSVisualHost:
			return child.build_context()
	return ECSVisualHostContext.new(world)

func get_root() -> Node:
	return _root

func has_slot(slot: StringName) -> bool:
	return _slots.has(slot) and _slots[slot] != null

func get_node(slot: StringName) -> Node:
	return _slots.get(slot)

func require_node(slot: StringName) -> Node:
	var node: Node = get_node(slot)
	if node == null:
		push_error("ECSVisualHostContext: missing slot '%s'" % slot)
	return node
