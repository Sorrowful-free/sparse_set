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
| `PACKED_STRING` | `ECSComponentPackedStringArray` | `PackedStringArray` | `""` |
| `PACKED_COLOR` | `ECSComponentPackedColorArray` | `PackedColorArray` | `Color.BLACK` |
| `PACKED_VECTOR2` | `ECSComponentPackedVector2Array` | `PackedVector2Array` | `Vector2.ZERO` |
| `PACKED_VECTOR3` | `ECSComponentPackedVector3Array` | `PackedVector3Array` | `Vector3.ZERO` |
| `PACKED_VECTOR4` | `ECSComponentPackedVector4Array` | `PackedVector4Array` | `Vector4.ZERO` |
| `BOOL` | `ECSComponentBoolArray` | `Array[bool]` | `false` |
| `INT` | `ECSComponentIntArray` | `Array[int]` | `0` |
| `FLOAT` | `ECSComponentFloatArray` | `Array[float]` | `0.0` |
| `AABB` | `ECSComponentAABBArray` | `Array[AABB]` | `AABB()` |
| `RECT2` | `ECSComponentRect2Array` | `Array[Rect2]` | `Rect2()` |
| `RECT2I` | `ECSComponentRect2iArray` | `Array[Rect2i]` | `Rect2i()` |
| `BASIS` | `ECSComponentBasisArray` | `Array[Basis]` | `Basis.IDENTITY` |
| `PLANE` | `ECSComponentPlaneArray` | `Array[Plane]` | `Plane()` |
| `PROJECTION` | `ECSComponentProjectionArray` | `Array[Projection]` | `Projection()` |
| `TRANSFORM2D` | `ECSComponentTransform2DArray` | `Array[Transform2D]` | `Transform2D.IDENTITY` |
| `TRANSFORM3D` | `ECSComponentTransform3DArray` | `Array[Transform3D]` | `Transform3D.IDENTITY` |
| `QUATERNION` | `ECSComponentQuaternionArray` | `Array[Quaternion]` | `Quaternion.IDENTITY` |
| `VECTOR2` | `ECSComponentVector2Array` | `Array[Vector2]` | `Vector2.ZERO` |
| `VECTOR2I` | `ECSComponentVector2iArray` | `Array[Vector2i]` | `Vector2i.ZERO` |
| `VECTOR3` | `ECSComponentVector3Array` | `Array[Vector3]` | `Vector3.ZERO` |
| `VECTOR3I` | `ECSComponentVector3iArray` | `Array[Vector3i]` | `Vector3i.ZERO` |
| `VECTOR4` | `ECSComponentVector4Array` | `Array[Vector4]` | `Vector4.ZERO` |
| `VECTOR4I` | `ECSComponentVector4iArray` | `Array[Vector4i]` | `Vector4i.ZERO` |
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
| `TWEEN` | `ECSComponentTweenArray` | `Array[Tween]` | `null` |
| `ANIMATION_PLAYER` | `ECSComponentAnimationPlayerArray` | `Array[AnimationPlayer]` | `null` |
| `ANIMATION_TREE` | `ECSComponentAnimationTreeArray` | `Array[AnimationTree]` | `null` |
| `MESH_INSTANCE_2D` | `ECSComponentMeshInstance2DArray` | `Array[MeshInstance2D]` | `null` |
| `MESH_INSTANCE_3D` | `ECSComponentMeshInstance3DArray` | `Array[MeshInstance3D]` | `null` |
| `MULTI_MESH_INSTANCE_2D` | `ECSComponentMultiMeshInstance2DArray` | `Array[MultiMeshInstance2D]` | `null` |
| `MULTI_MESH_INSTANCE_3D` | `ECSComponentMultiMeshInstance3DArray` | `Array[MultiMeshInstance3D]` | `null` |
| `RIGID_BODY_2D` | `ECSComponentRigidBody2DArray` | `Array[RigidBody2D]` | `null` |
| `RIGID_BODY_3D` | `ECSComponentRigidBody3DArray` | `Array[RigidBody3D]` | `null` |
| `CHARACTER_BODY_2D` | `ECSComponentCharacterBody2DArray` | `Array[CharacterBody2D]` | `null` |
| `CHARACTER_BODY_3D` | `ECSComponentCharacterBody3DArray` | `Array[CharacterBody3D]` | `null` |
| `STATIC_BODY_2D` | `ECSComponentStaticBody2DArray` | `Array[StaticBody2D]` | `null` |
| `STATIC_BODY_3D` | `ECSComponentStaticBody3DArray` | `Array[StaticBody3D]` | `null` |
| `AREA_2D` | `ECSComponentArea2DArray` | `Array[Area2D]` | `null` |
| `AREA_3D` | `ECSComponentArea3DArray` | `Array[Area3D]` | `null` |
| `COLLISION_SHAPE_2D` | `ECSComponentCollisionShape2DArray` | `Array[CollisionShape2D]` | `null` |
| `COLLISION_SHAPE_3D` | `ECSComponentCollisionShape3DArray` | `Array[CollisionShape3D]` | `null` |
| `COLLISION_POLYGON_2D` | `ECSComponentCollisionPolygon2DArray` | `Array[CollisionPolygon2D]` | `null` |
| `COLLISION_POLYGON_3D` | `ECSComponentCollisionPolygon3DArray` | `Array[CollisionPolygon3D]` | `null` |
| `SHAPE_2D` | `ECSComponentShape2DArray` | `Array[Shape2D]` | `null` |
| `SHAPE_3D` | `ECSComponentShape3DArray` | `Array[Shape3D]` | `null` |
| `NAVIGATION_AGENT_2D` | `ECSComponentNavigationAgent2DArray` | `Array[NavigationAgent2D]` | `null` |
| `NAVIGATION_AGENT_3D` | `ECSComponentNavigationAgent3DArray` | `Array[NavigationAgent3D]` | `null` |
| `TIMER` | `ECSComponentTimerArray` | `Array[Timer]` | `null` |

Строгие типы (`Array[T]`) задают тип и в API (`add_component(entity, value: T)`), и в самом хранилище. `PACKED_*` — плотные `Packed*Array`-буферы; `OBJECT` — generic-хранилище «любой `Object`» (буфер untyped `Array`, API типизирован `Object`).

Типизированные Node/RefCounted-подтипы (`TWEEN`, `ANIMATION_PLAYER`, `MESH_INSTANCE_*`, `MULTI_MESH_INSTANCE_*`, `RIGID_BODY_*`, `CHARACTER_BODY_*`, `AREA_*`, `NAVIGATION_AGENT_*`, `TIMER`) — это **типизация, а не новые возможности**: `NODE`/`OBJECT`/`RESOURCE` уже принимают любой подкласс, а отдельный тип даёт `Array[T]` вместо `Array[Node]` — доступ без `as`-каста. Добавляй только то, что системы читают на каждую сущность каждый кадр.

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
- Для объектов со сложным lifecycle (`Node` в дереве сцены) используйте reference-компонент (`NODE2D`/`NODE`) + Resource-**сервис** для пула/фабрики (ниже).

## Паттерн: reference-компонент + Resource-сервис

Идея: **ссылка на объект хранится в самом компоненте** (`NODE2D`, `NODE`, `RESOURCE`, `REFCOUNTED`) — это единственный источник правды. Пул/фабрика/navmesh — отдельный **сервис** (`Resource`), передаётся через `@export` в [`ECSSystemStrategy`](config/ecs_system_strategy.gd). Полный lifecycle — [INTENT_PIPELINE.md](INTENT_PIPELINE.md).

```gdscript
# addons/pgdecs/ecs/examples/services/ecs_node_pool.gd

class_name ECSNodePool extends Resource

func acquire() -> Node2D: ...      # взять из пула / инстанцировать
func release(node: Node) -> void: # вернуть/освободить
```

Компонент в ECS:

```gdscript
ecs.register_component(NODE_ID, ECSComponent.Type.NODE2D)

# После bind (intent system или spawn):
node_component.set_component(entity_id, pool.acquire())
```

Ноду из сцены создавай отдельной main-thread системой: blueprint обычным `spawn_one` / `spawn_batch` добавляет `PACKED_SCENE`, система инстанцирует её как `Node3D`, затем удаляет `PACKED_SCENE` и добавляет компонент `NODE3D` со ссылкой на инстанс. Пример: [`examples/node_entities/example_instantiate_node_system.gd`](examples/node_entities/example_instantiate_node_system.gd).

### Почему нет slot-реестров

Ранее в ECS хранился `Int32` slot (`-1` = нет), а объект — в side-table `ECSNodeRegistry` вне SoA. При reference-компонентах это избыточный слой:

- **Хранение** — `NODE2D` уже лежит в SoA per-entity, отдельная таблица не нужна.
- **Присутствие** — «нет привязки» как `-1` не выражается через query (фильтры только по членству). Reference-компонент превращает признак в членство архетипа.
- **Инвариант release** — два источника правды (slot + таблица) требовали дисциплины «release перед destroy». Остаётся один.
- **Скорость sync** — пропадает индирекция `registry.get_node(slot)` на каждую сущность.

Где side-table всё ещё уместен: **variable-length** данные, **дедуп/интернирование** (строки, id), **внешние identity** (wire-id, LOD grids). Но и они закрываются reference-компонентом (`REFCOUNTED`/`RESOURCE`) или int-компонентом (`NET_ID`) + **сервисом**-маппингом — без ключа-slot'а в SoA.

## String / Transform / RID

- **String (в SoA)** — `ecs.register_component(NAME_ID, ECSComponent.Type.PACKED_STRING)`; fast-path через `get_values_buffer()` / `set_value_at_slot` как у остальных packed-типов.
- **String (пул)** — `int` id в строковом пуле (`Dictionary` / `PackedStringArray` снаружи ECS), если нужен дедуп или каталог имён без копий в каждом чанке.
- **Transform** — `ECSComponent.Type.TRANSFORM2D` / `TRANSFORM3D` (буфер `Array[Transform2D/3D]`) или `PACKED_VECTOR3` + угол, если нужна плотная упаковка.
- **RID** — `ECSComponent.Type.RID` (буфер `Array[RID]`) или `Int64` (`get_id()` / `rid_from_int64()`) на границе Server API.

## Lifecycle (ответственность игры)

1. **Bind** — intent или spawn: `add_component(NODE)` + ссылка в компоненте (или сразу компонент в архетипе spawn'а).
2. **Sync** — система читает SoA, пишет в Node / Server.
3. **Release** — `INTENT_RELEASE` или вручную перед `destroy_entity`: `pool.release(node)` + `remove_component(NODE)`.
4. **Destroy** — `destroy_entity` после освобождения ссылок.

При удалении `Node` из сцены — gateway (`tree_exited` → intent или `destroy_entity`). ECS **не освобождает** `Node`/`Resource` автоматически: за lifecycle отвечает игра.

## Статус

- Хранилища выбираются через `ECSComponent.Type`: packed, строгие value/reference (`Array[T]`) и generic `OBJECT`.
- Объекты со сложным lifecycle (`Node`) — через reference-компонент, Resource-сервис (пул) и intent в игровом коде. Bridge-слой из 1.x **удалён**; slot-реестры (`ECSNodeRegistry` + `*_SLOT`) **удалены в 2.5** — см. [MIGRATION.md](MIGRATION.md), [CHANGELOG.md](CHANGELOG.md).
