extends RefCounted
class_name GECSPerfBootstrap

## Подготавливает дерево сцены для headless/editor perf-прогонов GECS.
static func prepare(tree: SceneTree) -> Node:
	_ensure_ecs_root_node(tree)
	_disable_gecs_debug(tree)
	return _get_holder(tree)

static func _ensure_ecs_root_node(tree: SceneTree) -> void:
	if tree.root.has_node("Root"):
		return
	var ecs_root := Node.new()
	ecs_root.name = "Root"
	tree.root.add_child(ecs_root)

static func _disable_gecs_debug(tree: SceneTree) -> void:
	var ecs: Node = tree.root.get_node_or_null("ECS")
	if ecs and "debug" in ecs:
		ecs.debug = false

static func _get_holder(tree: SceneTree) -> Node:
	var existing: Node = tree.root.get_node_or_null("GECSBenchmarkHolder")
	if existing:
		return existing
	var holder := Node.new()
	holder.name = "GECSBenchmarkHolder"
	tree.root.add_child(holder)
	return holder
