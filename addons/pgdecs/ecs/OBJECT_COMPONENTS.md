# Компоненты: хранилища, типы и объектные компоненты

Ядро PGDECS хранит значения в SoA-чанках. Тип хранилища выбирается при регистрации через enum `ECSComponent.Type` — собственный enum вместо `Variant.Type`.

```gdscript
ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
```

Зачем свой enum, а не `Variant.Type`:

- **Object-подтипы.** `Node`, `Node2D`, `Node3D`, `Resource`, `PackedScene`, `RefCounted` в `Variant.Type` все равны `TYPE_OBJECT` — их нельзя было различить.
- **Value-типы без `Packed*Array`.** `AABB`, `Rect2`, `Quaternion`, `Basis`, `Transform2D/3D`, `Vector2i/3i/4i` не имеют packed-буфера; они хранятся в типизированном `Array[T]`.
- Список типов расширяется нами, а не версией Godot.

## Группы типов

| Группа | Буфер | Default | Примеры |
|--------|-------|---------|---------|
| packed | `Packed*Array` | значение (`0`, `Vector2.ZERO`, …) | `PACKED_BYTE`, `PACKED_VECTOR2`, `PACKED_COLOR`, `PACKED_STRING` |
| value | `Array[T]` | значение (`false`, `AABB()`, `…IDENTITY`) | `BOOL`, `INT`, `FLOAT`, `AABB`, `VECTOR2`, `COLOR`, `STRING`, `STRINGNAME`, `NODEPATH`, `RID` |
| reference | `Array[T]` | `null` | `OBJECT`, `NODE`, `NODE2D`, `NODE3D`, `RESOURCE`, `PACKED_SCENE`, `REF_COUNTED` |

Полная таблица:

| enum | Класс | Буфер | Default |
|------|-------|-------|---------|
| `PACKED_BYTE` | `ECSComponentPackedByteArray` | `PackedByteArray` | `0` |
| `PACKED_INT64` | `ECSComponentPackedInt64Array` | `PackedInt64Array` | `0` |
| `PACKED_INT32` | `ECSComponentPackedInt32Array` | `PackedInt32Array` | `0` |
| `PACKED_FLOAT64` | `ECSComponentPackedFloat64Array` | `PackedFloat64Array` | `0.0` |
| `PACKED_FLOAT32` | `ECSComponentPackedFloat32Array` | `PackedFloat32Array` | `0.0` |
| `PACKED_VECTOR2` | `ECSComponentPackedVector2Array` | `PackedVector2Array` | `Vector2.ZERO` |
| `PACKED_VECTOR3` | `ECSComponentPackedVector3Array` | `PackedVector3Array` | `Vector3.ZERO` |
| `PACKED_VECTOR4` | `ECSComponentPackedVector4Array` | `PackedVector4Array` | `Vector4.ZERO` |
| `PACKED_COLOR` | `ECSComponentPackedColorArray` | `PackedColorArray` | `Color.BLACK` |
| `PACKED_STRING` | `ECSComponentPackedStringArray` | `PackedStringArray` | `""` |
| `BOOL` | `ECSComponentBoolArray` | `Array[bool]` | `false` |
| `INT` | `ECSComponentIntArray` | `Array[int]` | `0` |
| `FLOAT` | `ECSComponentFloatArray` | `Array[float]` | `0.0` |
| `AABB` | `ECSComponentAABBArray` | `Array[AABB]` | `AABB()` |
| `RECT2` | `ECSComponentRect2Array` | `Array[Rect2]` | `Rect2()` |
| `BASIS` | `ECSComponentBasisArray` | `Array[Basis]` | `Basis.IDENTITY` |
| `PLANE` | `ECSComponentPlaneArray` | `Array[Plane]` | `Plane()` |
| `TRANSFORM2D` | `ECSComponentTransform2DArray` | `Array[Transform2D]` | `Transform2D.IDENTITY` |
| `TRANSFORM3D` | `ECSComponentTransform3DArray` | `Array[Transform3D]` | `Transform3D.IDENTITY` |
| `QUATERNION` | `ECSComponentQuaternionArray` | `Array[Quaternion]` | `Quaternion.IDENTITY` |
| `VECTOR2` | `ECSComponentVector2Array` | `Array[Vector2]` | `Vector2.ZERO` |
| `VECTOR2I` | `ECSComponentVector2iArray` | `Array[Vector2i]` | `Vector2i.ZERO` |
| `VECTOR3I` | `ECSComponentVector3iArray` | `Array[Vector3i]` | `Vector3i.ZERO` |
| `VECTOR3` | `ECSComponentVector3Array` | `Array[Vector3]` | `Vector3.ZERO` |
| `VECTOR4I` | `ECSComponentVector4iArray` | `Array[Vector4i]` | `Vector4i.ZERO` |
| `VECTOR4` | `ECSComponentVector4Array` | `Array[Vector4]` | `Vector4.ZERO` |
| `COLOR` | `ECSComponentColorArray` | `Array[Color]` | `Color.BLACK` |
| `STRINGNAME` | `ECSComponentStringNameArray` | `Array[StringName]` | `&""` |
| `STRING` | `ECSComponentStringArray` | `Array[String]` | `""` |
| `NODEPATH` | `ECSComponentNodePathArray` | `Array[NodePath]` | `^""` |
| `RID` | `ECSComponentRIDArray` | `Array[RID]` | `RID()` |
| `RESOURCE` | `ECSComponentResourceArray` | `Array[Resource]` | `null` |
| `PACKED_SCENE` | `ECSComponentPackedSceneArray` | `Array[PackedScene]` | `null` |
| `NODE` | `ECSComponentNodeArray` | `Array[Node]` | `null` |
| `NODE2D` | `ECSComponentNode2DArray` | `Array[Node2D]` | `null` |
| `NODE3D` | `ECSComponentNode3DArray` | `Array[Node3D]` | `null` |
| `OBJECT` | `ECSComponentObjectArray` | `Array` | `null` |
| `REFCOUNTED` | `ECSComponentRefCountedArray` | `Array[RefCounted]` | `null` |

Строгие типы (`Array[T]`) задают тип и в API (`add_component(entity, value: T)`), и в самом хранилище. `PACKED_*` — плотные `Packed*Array`-буферы; `OBJECT` — generic-хранилище «любой `Object`» (буфер untyped `Array`, API типизирован `Object`); для конкретных подтипов используйте `NODE`, `RESOURCE`, `PACKED_SCENE` и т.д.

```gdscript
ecs.register_component(NODE_ID, ECSComponent.Type.NODE2D)      # Array[Node2D]
ecs.register_component(MESH_ID, ECSComponent.Type.RESOURCE)    # Array[Resource]
ecs.register_component(XFORM_ID, ECSComponent.Type.TRANSFORM3D) # Array[Transform3D]
```

## Семантика reference-типов

- Значения `OBJECT` / `NODE` / `NODE2D` / `NODE3D` / `RESOURCE` / `PACKED_SCENE` / `REF_COUNTED` хранятся **по ссылке**: `get_component` / `get_value_at_slot` / `get_values_buffer` возвращают ту же ссылку, что лежит в чанке, а `set_component` сохраняет переданную ссылку без копирования. Мутация результата меняет значение компонента у сущности.
- **Нужна независимая копия — дублируйте явно:** глубокая — `value.duplicate(true)`, поверхностная — `value.duplicate()`.
- `null` — валидное «пустое» значение; членство компонента определяется архетипом / `has_component`, отдельного флага наличия нет.
- value-типы (`AABB`, `Transform3D`, …) — value-семантика, как у `Vector2`: возвращается копия.

## Производительность

- packed-буферы (`Packed*Array`) — плотный SoA, лучший вариант для горячих данных.
- `Array[T]` (value и reference) менее плотный: значения боксятся, есть indirection и GC-давление для объектов; fast-path по `get_values_buffer()` почти не даёт выигрыша.
- У части value-типов есть **и packed, и `Array[T]`** вариант (`PACKED_VECTOR2` ↔ `VECTOR2`, `PACKED_COLOR` ↔ `COLOR`, `PACKED_STRING` ↔ `STRING`, `PACKED_INT32` ↔ `INT`, …). Различие только в буфере — для горячих данных берите `PACKED_*`.
- Для `AABB` / `Rect2` / `Plane` / `Quaternion` / `Basis` / `Transform*` / `Vector2i/3i/4i` / `StringName` / `NodePath` / `RID` packed-вариантов в Godot нет, поэтому `Array[T]` — единственный вариант.
- Для объектов со сложным lifecycle (`Node` в дереве сцены) по-прежнему предпочтителен slot + реестр (ниже).

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
const NODE_SLOT_ID: int = 20  # ECSComponent.Type.PACKED_INT32

# После bind (intent system или spawn):
slots.set_component(entity, registry.acquire())
```

### Slot-based vs handle-based реестр

Оба варианта — side-table вне SoA; различается **ключ** в реестре и API:

| Модель | Ключ в ECS | Типичный API реестра | Когда |
|--------|------------|----------------------|--------|
| **Slot-based** | `Int32` slot (`-1` = пусто) | `acquire()` / `release(slot)` / `get_node(slot)` | Пул нод/RID, эталон в `examples/registries/` |
| **Handle-based** | entity id или wire-id в компоненте | `get_or_register(key)` / `unregister(key)` | Сеть, привязка к внешнему id, LOD grids |

Для ссылочных компонентов (`NODE`, `RESOURCE`) «handle» — это само значение компонента, по которому система находит объект. Имена методов в игре могут отличаться от примеров аддона — контракт один: **bind → sync → release до destroy**.

## String / Transform / RID

- **String (в SoA)** — `ecs.register_component(NAME_ID, ECSComponent.Type.PACKED_STRING)`; fast-path через `get_values_buffer()` / `set_value_at_slot` как у остальных packed-типов.
- **String (пул)** — `int` id в строковом пуле (`Dictionary` / `PackedStringArray` снаружи ECS), если нужен дедуп или каталог имён без копий в каждом чанке.
- **Transform** — `ECSComponent.Type.TRANSFORM2D` / `TRANSFORM3D` (буфер `Array[Transform2D/3D]`) или `PACKED_VECTOR3` + угол, если нужна плотная упаковка.
- **RID** — `ECSComponent.Type.RID` (буфер `Array[RID]`) или `Int64` (`get_id()` / `rid_from_int64()`) на границе Server API.

## Lifecycle (ответственность игры)

1. **Bind** — intent или spawn: slot/ссылка в компоненте.
2. **Sync** — система читает SoA, пишет в registry / Node / Server.
3. **Release** — `INTENT_RELEASE` или вручную перед `destroy_entity`: `registry.release(slot)`.
4. **Destroy** — `destroy_entity` после освобождения ссылок.

При удалении `Node` из сцены — gateway (`tree_exited` → intent или `destroy_entity`). ECS **не освобождает** `Node`/`Resource` автоматически: за lifecycle отвечает игра.

## Статус

- Хранилища выбираются через `ECSComponent.Type`: packed, строгие value/reference (`Array[T]`) и generic `OBJECT`.
- Объекты со сложным lifecycle (`Node`) — через slot + реестр и intent в игровом коде. Bridge-слой из 1.x **удалён** — см. [MIGRATION.md](MIGRATION.md), [CHANGELOG.md](CHANGELOG.md).
