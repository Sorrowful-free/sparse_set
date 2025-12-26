class_name CommandBuffer extends RefCounted


func create_entity(component_ids: PackedInt64Array) -> int:
    return EntityIdsUtils.NULL_ENTITY_ID

func add_component(entity_id: int, component_id: int) -> void:
    pass ;

func remove_component(entity_id: int, component_id: int) -> void:
    pass ;

func destroy_entity(entity_id: int) -> void:
    pass ;