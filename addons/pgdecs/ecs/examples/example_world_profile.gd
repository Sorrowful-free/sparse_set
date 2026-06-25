extends ECSWorldProfile
class_name ECSExampleWorldProfile

## Пример профиля с дефолтными system_groups (simulation / network / frame).
## Bridge: bridge_registry_strategy + ECSBridgeSyncStrategy / ECSBridgeOrchestratorStrategy в system_strategies.

func _init() -> void:
	system_groups = ECSSystemRunGroups.default_group_configs()
