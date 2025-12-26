class_name SystemBase extends RefCounted
var _ecs_manager: EcsManager


func _init(ecs_manager: EcsManager) -> void:
    _ecs_manager = ecs_manager

# func update(delta: float) -> void:

#     pass

# func on_entity_added(entity_id: int) -> void:
#     pass

# func on_entity_removed(entity_id: int) -> void:
#     pass