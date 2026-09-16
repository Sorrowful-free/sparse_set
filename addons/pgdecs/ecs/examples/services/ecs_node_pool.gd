class_name ECSNodePool extends Resource

## Тонкий сервис (не реестр): выдаёт Node для reference-компонента и принимает его обратно.
## В ECS хранится **сама ссылка** (`NODE2D` / `NODE`), а не int-slot в side-table.
## См. [OBJECT_COMPONENTS.md](../../OBJECT_COMPONENTS.md) и [INTENT_PIPELINE.md](../../INTENT_PIPELINE.md).
##
## Контракт: `acquire()` → Node, `release(node)` → вернуть/освободить.
## Игра может заменить его своим пулом/фабрикой — системы зависят только от этих двух методов.

@export var node_scene: PackedScene

var _free_nodes: Array[Node] = []

func acquire() -> Node2D:
	if not _free_nodes.is_empty():
		return _free_nodes.pop_back() as Node2D
	if node_scene != null:
		return node_scene.instantiate() as Node2D
	return Node2D.new()

func release(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	if node.get_parent() != null:
		node.get_parent().remove_child(node)
	_free_nodes.append(node)

## Сколько нод сейчас в пуле (диагностика/тесты).
func available_count() -> int:
	return _free_nodes.size()

## Освободить закэшированные ноды (вызывать при reset мира).
func clear() -> void:
	for node: Node in _free_nodes:
		if is_instance_valid(node):
			node.free()
	_free_nodes.clear()
