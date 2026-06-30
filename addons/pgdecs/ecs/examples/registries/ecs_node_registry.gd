class_name ECSNodeRegistry extends Resource

## Side-table для Node: в ECS хранится int slot.
## См. [OBJECT_COMPONENTS.md](../../OBJECT_COMPONENTS.md) и [INTENT_PIPELINE.md](../../INTENT_PIPELINE.md).

var _nodes: Array = []
var _free: Array[int] = []

func acquire() -> int:
	if not _free.is_empty():
		return _free.pop_back()
	var slot: int = _nodes.size()
	_nodes.append(null)
	return slot

func release(slot: int) -> void:
	if slot < 0 or slot >= _nodes.size():
		return
	_nodes[slot] = null
	_free.append(slot)

func register(node: Node) -> int:
	var slot: int = acquire()
	_nodes[slot] = node
	return slot

func get_node(slot: int) -> Node:
	if slot < 0 or slot >= _nodes.size():
		return null
	return _nodes[slot] as Node

func unregister(slot: int) -> void:
	release(slot)

func clear() -> void:
	_nodes.clear()
	_free.clear()
