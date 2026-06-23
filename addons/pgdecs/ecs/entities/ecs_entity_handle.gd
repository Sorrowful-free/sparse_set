extends RefCounted

class_name ECSEntityHandle

const INDEX_MASK: int = 0xFFFFFFFF
const GENERATION_MASK: int = 0xFFFFFFFF

static func make(index: int, generation: int) -> int:
	return ((generation & GENERATION_MASK) << 32) | (index & INDEX_MASK)

static func index_of(handle: int) -> int:
	return handle & INDEX_MASK

static func generation_of(handle: int) -> int:
	return (handle >> 32) & GENERATION_MASK

static func is_valid_handle(handle: int) -> bool:
	return handle != 0
