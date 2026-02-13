extends RefCounted
class_name ECSTestRunner

## Минимальный раннер юнит-тестов: assert_* и запуск методов test_*.

var _passed: int = 0
var _failed: int = 0
var _current_name: String = ""

func _init() -> void:
	pass

# --- Assertions ---

func assert_true(condition: bool, message: String = "") -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		_push_fail("assert_true", message if message else "expected true")

func assert_false(condition: bool, message: String = "") -> void:
	if !condition:
		_passed += 1
	else:
		_failed += 1
		_push_fail("assert_false", message if message else "expected false")

func assert_eq(a: Variant, b: Variant, message: String = "") -> void:
	if _deep_equal(a, b):
		_passed += 1
	else:
		_failed += 1
		_push_fail("assert_eq", (message + " ") if message else "" + "expected %s == %s" % [a, b])

func assert_ne(a: Variant, b: Variant, message: String = "") -> void:
	if !_deep_equal(a, b):
		_passed += 1
	else:
		_failed += 1
		_push_fail("assert_ne", (message + " ") if message else "" + "expected %s != %s" % [a, b])

func assert_null(v: Variant, message: String = "") -> void:
	if v == null:
		_passed += 1
	else:
		_failed += 1
		_push_fail("assert_null", message if message else "expected null, got %s" % v)

func assert_not_null(v: Variant, message: String = "") -> void:
	if v != null:
		_passed += 1
	else:
		_failed += 1
		_push_fail("assert_not_null", message if message else "expected non-null")

func assert_gt(a: float, b: float, message: String = "") -> void:
	if a > b:
		_passed += 1
	else:
		_failed += 1
		_push_fail("assert_gt", message if message else "expected %s > %s" % [a, b])

func assert_lt(a: float, b: float, message: String = "") -> void:
	if a < b:
		_passed += 1
	else:
		_failed += 1
		_push_fail("assert_lt", message if message else "expected %s > %s" % [a, b])

func _deep_equal(a: Variant, b: Variant) -> bool:
	if a == null and b == null:
		return true
	if a is PackedInt64Array and b is PackedInt64Array:
		var pa: PackedInt64Array = a
		var pb: PackedInt64Array = b
		if pa.size() != pb.size():
			return false
		for i in range(pa.size()):
			if pa[i] != pb[i]:
				return false
		return true
	return a == b

func _push_fail(assertion: String, detail: String) -> void:
	print("  FAIL [%s] %s: %s" % [_current_name, assertion, detail])

# --- Run ---

func run_suite(suite_name: String, test_object: RefCounted) -> void:
	var methods: PackedStringArray = []
	for method_info in test_object.get_method_list():
		var name_str: String = method_info.get("name", "")
		if name_str.begins_with("test_"):
			methods.append(name_str)
	methods.sort()
	for method_name in methods:
		_current_name = method_name
		var callable: Callable = Callable(test_object, method_name)
		callable.call(self)

func get_passed() -> int:
	return _passed

func get_failed() -> int:
	return _failed

func get_total() -> int:
	return _passed + _failed

func reset() -> void:
	_passed = 0
	_failed = 0
	_current_name = ""

func print_summary(prefix: String = "") -> void:
	var total: int = get_total()
	var ok: bool = _failed == 0
	if prefix:
		print(prefix)
	print("  passed: %d  failed: %d  total: %d  %s" % [_passed, _failed, total, "OK" if ok else "FAILED"])
