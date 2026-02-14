extends RefCounted

class_name ECSEntityIdsUtils

## Единый размер чанка для архетипов и компонентов (см. ecs/DESIGN.md, фаза 0).
const NULL_ENTITY_ID: int = -1
const CHUNK_SIZE: int = 256

const GET_CHUNK_INDEX_BIT: int = 8
const GET_ENTITY_LOCAL_INDEX_BIT_MASK: int = 0xFF # 255 = CHUNK_SIZE-1

static func get_chunk_index(entity_id: int) -> int:
	return entity_id >> GET_CHUNK_INDEX_BIT

static func get_chunk_entity_index(entity_id: int) -> int:
	return entity_id & GET_ENTITY_LOCAL_INDEX_BIT_MASK
