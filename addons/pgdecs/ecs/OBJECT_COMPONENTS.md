# Объектные компоненты (Node, Transform, Resource)

Ядро PGDECS хранит **примитивные SoA-типы** (`PackedFloat32Array`, `PackedVector2Array`, `PackedStringArray` и т.д.).  
`Node`, `Resource`, `Transform3D` как Godot-объекты **не входят** в `ECSComponentFactory`.

**String** — исключение: поддерживается как `TYPE_PACKED_STRING_ARRAY` (`ECSComponentStringArray`) — одна `String` на entity в чанке. Альтернатива для каталогов/дедупа — `int` id + строковый пул вне ECS (ниже).

## Почему не в ядре

- Godot-объекты — reference types, GC, не ложатся в плотный SoA без indirection.
- Расширение factory под объекты размоет контракт производительности и усложнит codegen.
- Lifecycle `Node` (дерево сцены, `free()`) не совместим с чистым ECS storage.

## Паттерн: slot + Resource-реестр (side-table)

Идея: в ECS хранится **лёгкий slot** (`Int32`, `-1` = нет), объекты — в **Resource-реестре** вне ECS. Передача реестра — `@export` в [`ECSSystemStrategy`](config/ecs_system_strategy.gd). Полный lifecycle — [INTENT_PIPELINE.md](INTENT_PIPELINE.md).

```gdscript
# addons/pgdecs/ecs/examples/registries/ecs_node_registry.gd

class_name ECSNodeRegistry extends Resource

func acquire() -> int: ...
func release(slot: int) -> void: ...
func get_node(slot: int) -> Node: ...
```

Компонент в ECS:

```gdscript
const NODE_SLOT_ID: int = 20  # TYPE_PACKED_INT32_ARRAY

# После bind (intent system или spawn):
slots.set_component(entity, registry.acquire())
```

### Slot-based vs handle-based реестр

Оба варианта — side-table вне SoA; различается **ключ** в реестре и API:

| Модель | Ключ в ECS | Типичный API реестра | Когда |
|--------|------------|----------------------|--------|
| **Slot-based** | `Int32` slot (`-1` = пусто) | `acquire()` / `release(slot)` / `get_node(slot)` | Пул нод/RID, эталон в `examples/registries/` |
| **Handle-based** | entity id или wire-id в компоненте | `get_or_register(key)` / `unregister(key)` | Сеть, привязка к внешнему id, LOD grids |

В SoA всё равно только примитив; «handle» — это значение компонента, по которому реестр находит объект. Имена методов в игре могут отличаться от примеров аддона — контракт один: **bind → sync → release до destroy**.

## String / Transform

- **String (в SoA)** — `ecs.register_component(NAME_ID, TYPE_PACKED_STRING_ARRAY)`; fast-path через `get_values_buffer()` / `set_value_at_slot` как у остальных packed-типов.
- **String (пул)** — `int` id в строковом пуле (`Dictionary` / `PackedStringArray` снаружи ECS), если нужен дедуп или каталог имён без копий в каждом чанке.
- **Transform** — `Vector3` + rotation как отдельные примитивные компоненты (или `PackedVector3Array` + угол).
- **RID** — `Int64` (`get_id()` / `rid_from_int64()` на границе Server API).

## Lifecycle (ответственность игры)

1. **Bind** — intent или spawn: slot в SoA.
2. **Sync** — система читает SoA, пишет в registry / Node / Server.
3. **Release** — `INTENT_RELEASE` или вручную перед `destroy_entity`: `registry.release(slot)`.
4. **Destroy** — `destroy_entity` после освобождения slot'ов.

При удалении `Node` из сцены — gateway (`tree_exited` → intent или `destroy_entity`).

## Статус (v2.0)

Поддержка object types **только** через реестры + slot/intent в игровом коде. Bridge-слой из 1.x **удалён** — см. [MIGRATION.md](MIGRATION.md), [CHANGELOG.md](CHANGELOG.md).
