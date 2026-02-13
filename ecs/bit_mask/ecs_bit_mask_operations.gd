extends RefCounted

class_name BitMaskOperations

static func bit_test(num: int, bit: int) -> bool:
	return ((num >> bit) % 2 != 0)

static func bit_set(num: int, bit: int) -> int:
	return num | 1 << bit

static func bit_clear(num: int, bit: int) -> int:
	return num & ~(1 << bit)

static func bit_toggle(num: int, bit: int) -> int:
	return bit_clear(num, bit) if bit_test(num, bit) else bit_set(num, bit)

static func bit_match(numBig: int, numSmall: int) -> bool:
	return numSmall > 0 && (numSmall & numBig) == numSmall
