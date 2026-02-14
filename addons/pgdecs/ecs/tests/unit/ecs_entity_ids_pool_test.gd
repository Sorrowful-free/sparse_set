extends RefCounted
class_name ECSEntityIdsPoolTest

func test_first_id_is_one(runner: ECSTestRunner) -> void:
	var pool: ECSEntityIdsPool = ECSEntityIdsPool.new()
	runner.assert_eq(pool.get_next_entity_id(), 1)

func test_ids_increment(runner: ECSTestRunner) -> void:
	var pool: ECSEntityIdsPool = ECSEntityIdsPool.new()
	runner.assert_eq(pool.get_next_entity_id(), 1)
	runner.assert_eq(pool.get_next_entity_id(), 2)
	runner.assert_eq(pool.get_next_entity_id(), 3)

func test_reuse_after_free(runner: ECSTestRunner) -> void:
	var pool: ECSEntityIdsPool = ECSEntityIdsPool.new()
	var a: int = pool.get_next_entity_id()
	var b: int = pool.get_next_entity_id()
	pool.free_entity_id(b)
	var c: int = pool.get_next_entity_id()
	runner.assert_eq(c, b)

func test_multiple_free_reuse(runner: ECSTestRunner) -> void:
	var pool: ECSEntityIdsPool = ECSEntityIdsPool.new()
	for i in range(5):
		var tmp = pool.get_next_entity_id()
	pool.free_entity_id(3)
	pool.free_entity_id(5)
	runner.assert_eq(pool.get_next_entity_id(), 5)
	runner.assert_eq(pool.get_next_entity_id(), 3)
	runner.assert_eq(pool.get_next_entity_id(), 6)
