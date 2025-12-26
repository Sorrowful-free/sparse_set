extends RefCounted

class_name EntityIdsUtils

const NULL_ENTITY_ID: int = -1

static func get_chunk_index(entity_id: int, chunk_capacity: int) -> int:
	return entity_id / chunk_capacity

static func get_chunk_entity_index(entity_id: int, chunk_capacity: int) -> int:
	return entity_id % chunk_capacity
