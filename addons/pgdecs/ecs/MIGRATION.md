# Migration Guide (Breaking API)

Этот документ покрывает миграцию на strict packed API в `ECSManager`.

## Что изменилось

- Удалены varargs-методы:
  - `create_entity(...)`
  - `create_entities(count, ...)`
  - `precache_archetype(...)`
- Используются только typed packed-методы:
  - `create_entity_packed(component_ids: PackedInt64Array)`
  - `create_entities_packed(count: int, component_ids: PackedInt64Array)`
  - `precache_archetype_packed(component_ids: PackedInt64Array)`

## Быстрые замены

```gdscript
# Было
var e := ecs.create_entity(POSITION_ID, HEALTH_ID)
var ids := ecs.create_entities(1000, POSITION_ID)
ecs.precache_archetype(POSITION_ID, HEALTH_ID)

# Стало
var e := ecs.create_entity_packed(PackedInt64Array([POSITION_ID, HEALTH_ID]))
var ids := ecs.create_entities_packed(1000, PackedInt64Array([POSITION_ID]))
ecs.precache_archetype_packed(PackedInt64Array([POSITION_ID, HEALTH_ID]))
```

## Почему так

- Явный тип входа уменьшает двусмысленность API.
- Упрощается hot path: нет varargs-конверсий в runtime.
- Стабильнее интеграция с `ECSCommandBuffer` и тестовой инфраструктурой.
