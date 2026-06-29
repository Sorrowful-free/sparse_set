extends ECSWorldProfile
class_name ECSExampleWorldProfile

## Пример профиля с дефолтными system_groups (simulation / network / frame).
## Intent pipeline: см. [ExampleIntentWorldProfile](example_intent_world_profile.gd).

func _init() -> void:
	system_groups = ECSSystemRunGroups.default_group_configs()
