extends RefCounted
class_name ECSSparseSetTest

func test_add_has_remove(runner: ECSTestRunner) -> void:
	var set: ECSSparseSet = ECSSparseSet.new()
	set.add(5)
	runner.assert_true(set.has(5))
	runner.assert_eq(set.size(), 1)
	set.remove(5)
	runner.assert_false(set.has(5))
	runner.assert_eq(set.size(), 0)

func test_swap_remove_middle(runner: ECSTestRunner) -> void:
	var set: ECSSparseSet = ECSSparseSet.new()
	set.add(1)
	set.add(2)
	set.add(3)
	set.remove(2)
	runner.assert_false(set.has(2))
	runner.assert_true(set.has(1))
	runner.assert_true(set.has(3))
	runner.assert_eq(set.size(), 2)

func test_remove_nonexistent_and_negative(runner: ECSTestRunner) -> void:
	var set: ECSSparseSet = ECSSparseSet.new()
	set.add(1)
	set.remove(99)
	set.remove(-1)
	runner.assert_eq(set.size(), 1)

func test_clear_and_get_ids(runner: ECSTestRunner) -> void:
	var set: ECSSparseSet = ECSSparseSet.new()
	set.add(10)
	set.add(20)
	var ids_before: PackedInt64Array = set.get_ids()
	runner.assert_eq(ids_before.size(), 2)
	set.clear()
	runner.assert_eq(set.size(), 0)
	runner.assert_eq(set.get_ids().size(), 0)
