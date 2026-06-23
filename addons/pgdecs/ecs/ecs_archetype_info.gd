extends RefCounted

class_name ECSArchetypeInfo

var bitmask: ECSBitMask
var packed: PackedInt64Array

func _init(p_bitmask: ECSBitMask, p_packed: PackedInt64Array) -> void:
	bitmask = p_bitmask
	packed = p_packed
