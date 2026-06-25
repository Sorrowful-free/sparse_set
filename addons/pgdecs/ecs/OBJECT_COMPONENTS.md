# Объектные компоненты (Node, String, Transform)

Ядро PGDECS хранит только **примитивные SoA-типы** (`PackedFloat32Array`, `PackedVector2Array` и т.д.).  
`Node`, `String`, `Resource`, `Transform` **не входят** в `ECSComponentFactory` и не планируются в ядре.

## Почему не в ядре

- Godot-объекты — reference types, GC, не ложатся в плотный SoA без indirection.
- Расширение factory под объекты размоет контракт производительности и усложнит codegen.
- Lifecycle `Node` (дерево сцены, `free()`) не совместим с чистым ECS storage.

## Паттерн: registry bridge (реестр снаружи ECS)

Идея: в ECS хранится **лёгкий идентификатор** (slot / handle), а сами объекты — в side-table.

```gdscript
# Пример вне ядра (addons/pgdecs/ecs/examples/object_registry_demo.gd)

class_name ECSNodeRegistry extends RefCounted

var _nodes: Array[Node] = []

func register(node: Node) -> int:
    var slot: int = _nodes.size()
    _nodes.append(node)
    return slot

func get_node(slot: int) -> Node:
    if slot < 0 or slot >= _nodes.size():
        return null
    return _nodes[slot]

func unregister(slot: int) -> void:
    if slot >= 0 and slot < _nodes.size():
        _nodes[slot] = null
```

Компонент в ECS — обычный `ECSComponentInt32Array` (или Int64) с `registry_slot`:

```gdscript
const NODE_SLOT_ID: int = 10

func spawn_visual(ecs: ECSManager, registry: ECSNodeRegistry, node: Node) -> int:
    var slot: int = registry.register(node)
    var entity: int = ecs.create_entity(POSITION_ID, NODE_SLOT_ID)
    var slots: ECSComponentInt32Array = ecs.get_component_array(NODE_SLOT_ID)
    slots.set_component(entity, slot)
    return entity

func destroy_visual(ecs: ECSManager, registry: ECSNodeRegistry, entity: int) -> void:
    var slots: ECSComponentInt32Array = ecs.get_component_array(NODE_SLOT_ID)
    var slot: int = slots.get_component(entity)
    registry.unregister(slot)
    ecs.destroy_entity(entity)
```

## String / Transform

- **String** — хранить `int` id в строковом пуле (`Dictionary[int, String]` или packed indices + `PackedStringArray`).
- **Transform** — разбить на `Vector3` position + `Quaternion` rotation (или `Vector3` + `Vector3` euler) как отдельные примитивные компоненты; не один blob `Transform`.

## Lifecycle

1. При `destroy_entity` — сначала прочитать slot из компонента, очистить реестр, затем `ecs.destroy_entity`.
2. При удалении `Node` из сцены — подписаться на `tree_exited` и удалить сущность из ECS (или пометить slot invalid).

## Статус

Планируется поддержка **только через реестры и примитивные компоненты-индексы**. Ядро ECS не будет расширено под object types.

## Visual registry

Presentation-слой: [`ECSVisualHost`](presentation/ecs_visual_host.gd), [`ECSVisualBackend`](presentation/ecs_visual_backend.gd), [`ECSVisualRegistry`](presentation/ecs_visual_registry.gd). Подключение через [`ECSVisualRegistryStrategy`](config/ecs_visual_registry_strategy.gd) в `ECSWorldProfile` (как системы).

Примитивные компоненты (регистрируются в игре через [`ECSComponentRegistryStrategy`](config/ecs_component_registry_strategy.gd)):

| Component | Storage | Смысл |
|-----------|---------|--------|
| `VISUAL_TYPE` | `TYPE_PACKED_INT32_ARRAY` | ключ backend (какой MultiMesh / пул) |
| `VISUAL_SUBTYPE` | `TYPE_PACKED_INT32_ARRAY` | вариант внутри type (свой enum на type) |
| `VISUAL_HANDLE` | `TYPE_PACKED_INT32_ARRAY` | opaque instance (`-1` = нет) |

Lifecycle:

1. **Spawn:** `handle = registry.acquire(visual_type, entity_id, ecs)` → записать handle + type/subtype в SoA-компоненты.
2. **Sync:** `ECSWorld._process` вызывает `registry.sync_all(ecs, delta)` после систем.
3. **Destroy:** `registry.release_entity(entity_id, ecs)` **до** `destroy_entity` (читает type/handle из SoA).

**LOD:** смена Skeletal → VAT → MultiMesh = смена `VISUAL_TYPE` (другой backend), не subtype. Опционально `APPEARANCE_VARIANT` + `LOD_LEVEL` — компоненты игры. Hysteresis на порогах — в игровой LOD-системе.

Конкретные backend'ы (MultiMesh, node pool, Skeletal) — **реализация в игре**, не в pgdecs.
