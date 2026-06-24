# Migration Guide (Breaking API)

Этот документ покрывает API создания сущностей в `ECSManager`.

## Текущая модель (два слоя)

| Слой | Методы | Когда |
|---|---|---|
| **Внешний** | `create_entity`, `create_entities`, `precache_archetype` (`Array[int]`) | Игровой код, setup, разовые вызовы |
| **Hot path** | `create_entity_packed`, `create_entities_packed`, `precache_archetype_packed` | Циклы, батчи, command buffer execute |
| **Предефайн** | `prepare_archetype([...])` → `PackedInt64Array` | Один раз в `_setup`, дальше `*_packed` |

## Быстрые замены

```gdscript
# Удобный внешний API
var e := ecs.create_entity([POSITION_ID, HEALTH_ID])
var ids := ecs.create_entities(1000, [POSITION_ID])
ecs.precache_archetype([POSITION_ID, HEALTH_ID])

# Hot path (без аллокации Array на каждый вызов)
var player_arch := ecs.prepare_archetype([POSITION_ID, HEALTH_ID])
ecs.create_entity_packed(player_arch)
ecs.create_entities_packed(100, player_arch)
```

## Историческая заметка

Ранее существовали varargs `create_entity(a, b, c)` — заменены на явный `Array[int]` + внутренний `PackedInt64Array` для предсказуемости типов и hot path.
