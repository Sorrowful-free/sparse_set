extends GutTest
class_name ECSSparseSetTest

func test_add_has_remove() -> void:
	var set: ECSSparseSet = ECSSparseSet.new()
	set.add(5)
	assert_true(set.has(5))
	assert_eq(set.size(), 1)
	set.remove(5)
	assert_false(set.has(5))
	assert_eq(set.size(), 0)

func test_swap_remove_middle() -> void:
	var set: ECSSparseSet = ECSSparseSet.new()
	set.add(1)
	set.add(2)
	set.add(3)
	set.remove(2)
	assert_false(set.has(2))
	assert_true(set.has(1))
	assert_true(set.has(3))
	assert_eq(set.size(), 2)

func test_remove_nonexistent_and_negative() -> void:
	var set: ECSSparseSet = ECSSparseSet.new()
	set.add(1)
	set.remove(99)
	set.remove(-1)
	assert_eq(set.size(), 1)

func test_clear_and_get_ids() -> void:
	var set: ECSSparseSet = ECSSparseSet.new()
	set.add(10)
	set.add(20)
	var ids_before: PackedInt64Array = set.get_ids()
	assert_eq(ids_before.size(), 2)
	set.clear()
	assert_eq(set.size(), 0)
	assert_eq(set.get_ids().size(), 0)
