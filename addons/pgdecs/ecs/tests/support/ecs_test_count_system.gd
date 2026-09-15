class_name ECSTestCountSystem extends ECSSystemBase

var update_count: int = 0

func process_system(_delta: float) -> void:
	update_count += 1
