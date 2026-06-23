extends RefCounted

class_name ECSEntityIdsUtils

## Единый размер чанка для архетипов и компонентов (см. ecs/DESIGN.md).
const NULL_ENTITY_ID: int = -1
const CHUNK_SIZE: int = 256

const GET_CHUNK_INDEX_BIT: int = 8
const GET_ENTITY_LOCAL_INDEX_BIT_MASK: int = 0xFF

## Принимает entity **index** (младшие 32 бита handle), не полный handle.
static func get_chunk_index(entity_index: int) -> int:
	return entity_index >> GET_CHUNK_INDEX_BIT

## Принимает entity **index**, не полный handle.
static func get_chunk_entity_index(entity_index: int) -> int:
	return entity_index & GET_ENTITY_LOCAL_INDEX_BIT_MASK

static func slot_from_handle(handle: int) -> int:
	return get_chunk_entity_index(ECSEntityHandle.index_of(handle))

static func chunk_index_from_handle(handle: int) -> int:
	return get_chunk_index(ECSEntityHandle.index_of(handle))
