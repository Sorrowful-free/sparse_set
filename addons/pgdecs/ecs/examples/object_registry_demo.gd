class_name ECSNodeRegistry extends RefCounted

## Side-table для Node: в ECS хранится int slot. См. [OBJECT_COMPONENTS.md](../OBJECT_COMPONENTS.md).

var _nodes: Array[Node] = []

func register(node: Node) -> int:
	var slot: int = _nodes.size()
	_nodes.append(node)
	return slot

func get_node(slot: int) -> Node:
	if slot < 0 or slot >= _nodes.size():
		return null
	return _nodes[slot]

func unregister(slot: int) -> void:
	if slot >= 0 and slot < _nodes.size():
		_nodes[slot] = null
