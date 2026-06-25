extends ECSWorldProfile
class_name ECSExampleWorldProfile

## Пример профиля с дефолтными system_groups (simulation / network / frame).
## В inspector можно переопределить hz, hook и run_group у strategies.

func _init() -> void:
	system_groups = ECSSystemRunGroups.default_group_configs()
