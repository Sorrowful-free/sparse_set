extends RefCounted
class_name ECSBitMaskTest

func test_bit_set_and_test(runner: ECSTestRunner) -> void:
	var mask: ECSBitMask = ECSBitMask.new(4)
	mask.bit_set(0, true)
	mask.bit_set(1, true)
	mask.bit_set(2, true)
	runner.assert_true(mask.bit_test(0))
	runner.assert_true(mask.bit_test(1))
	runner.assert_true(mask.bit_test(2))
	runner.assert_false(mask.bit_test(3))

func test_bit_clear_all(runner: ECSTestRunner) -> void:
	var mask: ECSBitMask = ECSBitMask.new(4)
	mask.bit_set(1, true)
	mask.bit_clear_all()
	runner.assert_false(mask.bit_test(1))

func test_bit_match(runner: ECSTestRunner) -> void:
	var big: ECSBitMask = ECSBitMask.new(4)
	big.bit_set(1, true)
	big.bit_set(2, true)
	var small: ECSBitMask = ECSBitMask.new(3)
	small.bit_set(1, true)
	runner.assert_true(big.bit_match(small))
	small.bit_set(2, true)
	runner.assert_true(big.bit_match(small))
	small.bit_set(3, true)
	runner.assert_false(big.bit_match(small))

func test_bit_has_any(runner: ECSTestRunner) -> void:
	var a: ECSBitMask = ECSBitMask.new(4)
	a.bit_set(1, true)
	var b: ECSBitMask = ECSBitMask.new(4)
	b.bit_set(2, true)
	var c: ECSBitMask = ECSBitMask.new(4)
	c.bit_set(1, true)
	runner.assert_false(a.bit_has_any(b))
	runner.assert_true(a.bit_has_any(c))

func test_bit_hash_stable_for_same_bits(runner: ECSTestRunner) -> void:
	var mask_a: ECSBitMask = ECSBitMask.new(3)
	mask_a.bit_set(1, true)
	mask_a.bit_set(2, true)
	var mask_b: ECSBitMask = ECSBitMask.new(64)
	mask_b.bit_set(1, true)
	mask_b.bit_set(2, true)
	runner.assert_eq(mask_a.bit_hash(), mask_b.bit_hash())

func test_bit_resize_boundary_64(runner: ECSTestRunner) -> void:
	var mask: ECSBitMask = ECSBitMask.new(64)
	runner.assert_eq(mask._bits.size(), 1)
	mask.bit_set(63, true)
	runner.assert_true(mask.bit_test(63))

func test_bit_match_zero_word_is_noop(runner: ECSTestRunner) -> void:
	var big: ECSBitMask = ECSBitMask.new(100)
	big.bit_set(1, true)
	var small: ECSBitMask = ECSBitMask.new(100)
	small.bit_set(1, true)
	runner.assert_true(big.bit_match(small))

func test_bit_test_out_of_bounds_returns_false(runner: ECSTestRunner) -> void:
	var mask: ECSBitMask = ECSBitMask.new(2)
	runner.assert_false(mask.bit_test(100))
