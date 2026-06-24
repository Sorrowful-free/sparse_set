class_name ECSTestCountSystem extends ECSSystemBase

var update_count: int = 0

func update(_delta: float) -> void:
	update_count += 1
