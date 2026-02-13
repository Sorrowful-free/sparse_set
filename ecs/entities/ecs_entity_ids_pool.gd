class_name EntityIdsPool extends RefCounted

var _next_entity_id: int = 0
var _free_entity_ids: PackedInt64Array = PackedInt64Array()

func get_next_entity_id() -> int:
	var free_entity_size: int = _free_entity_ids.size()
	if free_entity_size > 0:
		var entity_id: int = _free_entity_ids[free_entity_size - 1]
		_free_entity_ids.resize(free_entity_size - 1)
		return entity_id
	_next_entity_id += 1
	return _next_entity_id

func free_entity_id(entity_id: int) -> void:
	_free_entity_ids.append(entity_id)
