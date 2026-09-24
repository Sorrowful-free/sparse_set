extends ECSSystemChunkBase
class_name ExampleInstantiateNodeSystem

## Пример: инстанцирование сцены из компонента `PACKED_SCENE` и запись ссылки
## на созданную ноду в reference-компонент `VISUAL`.
##
## Сущность уже несёт все три компонента; `VISUAL` пуст до первого прохода.
## Повторное инстанцирование отсекается проверкой `visual_buf[slot] != null` —
## без неё каждый прогон создавал бы новую ноду, а прежняя утекала бы.
##
## Main thread: `add_child` в worker pool недопустим.

const Registry := ExampleInstantiateNodeComponentRegistryStrategy

var _root_node: Node


func _init(ecs_manager: ECSManager, root_node: Node) -> void:
	_root_node = root_node
	super(ecs_manager)


func build_query() -> ECSQuery:
	return ECSQueryBuilder.new()\
		.with_component(Registry.Component.POSITION)\
		.with_component(Registry.Component.VISUAL)\
		.with_component(Registry.Component.PACKED_SCENE)\
		.build(get_ecs_manager())


func process_chunk(chunk: ECSQueryChunk, _delta: float) -> void:
	var position_chunk: ECSComponentPackedVector3ArrayChunk = chunk.get_component_chunk(
		Registry.Component.POSITION
	) as ECSComponentPackedVector3ArrayChunk
	var visual_chunk: ECSComponentNode3DArrayChunk = chunk.get_component_chunk(
		Registry.Component.VISUAL
	) as ECSComponentNode3DArrayChunk
	var scene_chunk: ECSComponentPackedSceneArrayChunk = chunk.get_component_chunk(
		Registry.Component.PACKED_SCENE
	) as ECSComponentPackedSceneArrayChunk
	if position_chunk == null or visual_chunk == null or scene_chunk == null:
		return

	# Буфер — плотный массив архетипа целиком, индексируется СЛОТОМ, не `i`.
	var slots: PackedInt32Array = chunk.get_dense_slots()
	var position_buf: PackedVector3Array = position_chunk.get_values_buffer()
	var visual_buf: Array[Node3D] = visual_chunk.get_values_buffer()
	var scene_buf: Array[PackedScene] = scene_chunk.get_values_buffer()

	for i: int in range(chunk.get_entity_count()):
		var slot: int = slots[i]
		if visual_buf[slot] != null:
			continue

		var scene: PackedScene = scene_buf[slot]
		if scene == null:
			continue

		var node: Node3D = scene.instantiate() as Node3D
		if node == null:
			push_error("ExampleInstantiateNodeSystem: корень сцены не Node3D")
			continue

		node.position = position_buf[slot]
		_root_node.add_child(node)
		visual_chunk.set_value_at_slot(slot, node)
