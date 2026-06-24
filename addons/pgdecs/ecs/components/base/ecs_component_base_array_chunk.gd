@abstract class_name ECSComponentBaseArrayChunk extends RefCounted

var _value_version: int = 0

func _init() -> void:
	pass

func get_value_version() -> int:
	return _value_version

func get_slot_count() -> int:
	return ECSEntityIdsUtils.CHUNK_SIZE

@abstract func get_value_at_slot(slot_index: int)
@abstract func set_value_at_slot(slot_index: int, component_value) -> void

@abstract func remove_component(index: int) -> void
@abstract func remove_components_batch(indices: PackedInt32Array) -> void
@abstract func add_components_batch(entity_ids: PackedInt64Array) -> void

func clear() -> void:
	pass
