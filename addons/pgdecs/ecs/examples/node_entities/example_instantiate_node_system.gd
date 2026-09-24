extends ECSSystemChunkBase
class_name ExampleInstantiateNodeSystem

var _root_node: Node

func _init() -> void:
	super()

func build_query() -> ECSQuery:
 return ECSQueryBuilder.new()\
  .with_component(ExampleInstantiateNodeComponentRegistryStrategy.Component.POSITION)\
  .with_component(ExampleInstantiateNodeComponentRegistryStrategy.Component.VISUAL)\
  .with_component(ExampleInstantiateNodeComponentRegistryStrategy.Component.PACKED_SCENE)\
  .build(get_ecs_manager())

func process_chunk(chunk: ECSQueryChunk, _delta: float) -> void:
 var entities_count := chunk.get_entity_count()
 if entities_count == 0:
  return

 var position_chunk : ECSComponentVector3ArrayChunk = chunk.get_component_chunk(ExampleInstantiateNodeComponentRegistryStrategy.Component.POSITION)
 var visual_chunk : ECSComponentNode3DArrayChunk = chunk.get_component_chunk(ExampleInstantiateNodeComponentRegistryStrategy.Component.VISUAL)
 var packed_scene_chunk : ECSComponentPackedSceneArrayChunk = chunk.get_component_chunk(ExampleInstantiateNodeComponentRegistryStrategy.Component.PACKED_SCENE)

 var position_values := position_chunk.get_values_buffer()
 var visual_values := visual_chunk.get_values_buffer()
 var packed_scene_values := packed_scene_chunk.get_values_buffer()

 for i in entities_count:
  var position_value := position_values.get(i)
  var visual_value := visual_values.get(i)
  var packed_scene_value := packed_scene_values.get(i)

  var node := packed_scene_value.instance()
  node.set_position(position_value)
  _root_node.add_child(node)
