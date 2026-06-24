extends GutTest
class_name ECSEntityIdsPoolTest

func test_first_handle_is_valid() -> void:
	var pool: ECSEntityIdsPool = ECSEntityIdsPool.new()
	var handle: int = pool.get_next_entity_id()
	assert_true(ECSEntityHandle.is_valid_handle(handle))
	assert_true(pool.is_alive(handle))
	assert_eq(ECSEntityHandle.index_of(handle), 0)
	assert_eq(ECSEntityHandle.generation_of(handle), 1)

func test_handles_increment_index() -> void:
	var pool: ECSEntityIdsPool = ECSEntityIdsPool.new()
	var h1: int = pool.get_next_entity_id()
	var h2: int = pool.get_next_entity_id()
	var h3: int = pool.get_next_entity_id()
	assert_eq(ECSEntityHandle.index_of(h1), 0)
	assert_eq(ECSEntityHandle.index_of(h2), 1)
	assert_eq(ECSEntityHandle.index_of(h3), 2)

func test_reuse_after_free() -> void:
	var pool: ECSEntityIdsPool = ECSEntityIdsPool.new()
	var h_a: int = pool.get_next_entity_id()
	var h_b: int = pool.get_next_entity_id()
	pool.free_entity_id(h_b)
	assert_false(pool.is_alive(h_b))
	var h_c: int = pool.get_next_entity_id()
	assert_eq(ECSEntityHandle.index_of(h_c), ECSEntityHandle.index_of(h_b))
	assert_ne(ECSEntityHandle.generation_of(h_c), ECSEntityHandle.generation_of(h_b))

func test_double_free_rejected() -> void:
	var pool: ECSEntityIdsPool = ECSEntityIdsPool.new()
	var handle: int = pool.get_next_entity_id()
	pool.free_entity_id(handle)
	pool.free_entity_id(handle)
	assert_push_error("double free")
	var h2: int = pool.get_next_entity_id()
	var h3: int = pool.get_next_entity_id()
	assert_eq(ECSEntityHandle.index_of(h2), ECSEntityHandle.index_of(handle))
	assert_eq(ECSEntityHandle.index_of(h3), 1)
