# Migration Guide (Breaking API)

Этот документ покрывает API создания сущностей в `ECSManager`.

## 2.5 — slot-реестры удалены

Внешний объект хранится не как `Int32`-slot в side-table, а как **reference-компонент**: в SoA лежит сама ссылка (`ECSComponent.Type.NODE2D`).

```gdscript
# было (2.0)
var registry: ECSNodeRegistry = dependencies.node_registry
var slot: int = registry.acquire()                 # -1 = нет привязки
slots.set_component(entity_id, slot)               # NODE_SLOT (PACKED_INT32)
# ... и при sync: registry.get_node(slot)

# стало (2.5)
cb.add_component(entity_id, ExampleIntentIds.NODE, dependencies.node_pool.acquire()) # NODE2D
```

| Шаг | Было (slot + реестр) | Стало (reference-компонент) |
|-----|----------------------|------------------------------|
| Схема | `NODE_SLOT` (`PACKED_INT32`) + `INVALID_SLOT` (`-1` = нет) | `ExampleIntentIds.NODE` → `ECSComponent.Type.NODE2D` |
| Зависимости | `dependencies.node_registry: ECSNodeRegistry` | `dependencies.node_pool: ECSNodePool` |
| Bind | `registry.acquire()` → slot → `slots.set_component(...)` | `add_component(NODE, pool.acquire())` |
| Sync | `registry.get_node(slot)` на каждую сущность | ссылка из буфера компонента напрямую |
| Release | `registry.release(slot)` + slot = `INVALID_SLOT` | `pool.release(node)` + `remove_component(NODE)` |
| «Есть привязка» | не выражается через query (нужен `slot >= 0`) | `with_component(NODE)` / `without_component(NODE)` |
| Сброс мира | `registry.clear()` | `pool.clear()` — сервис ядру неизвестен, `ecs.reset()` его не чистит |

Удалено: `examples/registries/` (`ECSNodeRegistry`). Добавлено: `examples/services/ecs_node_pool.gd` (`ECSNodePool`). Переименовано: `ExampleRegistrySyncSystem` / `ExampleRegistrySyncStrategy` → `ExampleNodeSyncSystem` / `ExampleNodeSyncStrategy`.

## 2.2.1 — snake_case имён папок/файлов кодогенерации

Папки и файлы сгенерированных компонентов переименованы в snake_case (`ECSComponent.file_slug()`): `generated/packedvector4/` → `generated/packed_vector4/`, `ecs_component_packed_vector4_array.gd`. Также `nodepath` → `node_path`, `stringname` → `string_name`, `packedscene` → `packed_scene`, `refcounted` → `ref_counted`. Имена классов (`ECSComponentPackedVector4Array`) **не меняются** — переименовываются только пути.

Проще всего: удалить каталог `components/generated/` целиком и перегенерировать.

## 2.2 — Packed-компоненты: переименование классов + новые типы (breaking)

### Классы packed-компонентов

Сгенерированные классы packed-хранилищ получили префикс `Packed` (согласовано с `PACKED_*` в `ECSComponent.Type`):

| Было | Стало |
|------|-------|
| `ECSComponentByteArray` | `ECSComponentPackedByteArray` |
| `ECSComponentInt32Array` | `ECSComponentPackedInt32Array` |
| `ECSComponentInt64Array` | `ECSComponentPackedInt64Array` |
| `ECSComponentFloat32Array` | `ECSComponentPackedFloat32Array` |
| `ECSComponentFloat64Array` | `ECSComponentPackedFloat64Array` |
| `ECSComponentVector2Array` | `ECSComponentPackedVector2Array` |
| `ECSComponentVector3Array` | `ECSComponentPackedVector3Array` |
| `ECSComponentVector4Array` | `ECSComponentPackedVector4Array` |
| `ECSComponentColorArray` | `ECSComponentPackedColorArray` |
| `ECSComponentStringArray` | `ECSComponentPackedStringArray` |

Чанки — аналогично (`…ArrayChunk`). Значения enum (`ECSComponent.Type.PACKED_*`) и API `register_component` **не менялись** — меняются только имена классов и папок сгенерированных файлов (`generated/byte/` → `generated/packed_byte/`; см. 2.2.1 про snake_case).

> Важно: имена `ECSComponentVector2Array`, `ECSComponentVector3Array`, `ECSComponentVector4Array`, `ECSComponentColorArray`, `ECSComponentStringArray` **заняты новыми непакованными типами** (`Array[Vector2]`, `Array[Color]`, `Array[String]`). Если код/сцены ссылались на них как на packed — замените на `…Packed…`.

### Новые типы

Добавлены строгие хранилища `Array[T]`: `BOOL`, `INT`, `FLOAT`, `PLANE`, `VECTOR2`, `VECTOR3`, `VECTOR4`, `COLOR`, `STRINGNAME`, `STRING`, `NODEPATH`, `RID`. Полный список и буферы — [OBJECT_COMPONENTS.md](OBJECT_COMPONENTS.md).

### Codegen

- Ключ `packed_type` → `array_type` (значение — тип буфера: `Packed*Array` или `Array[T]`).
- Шаблон чанка: `{packed_type}` → `{array_type}`; инициализация буфера — `{buffer_init}` (`Packed*Array()` для packed, `[]` для `Array[T]`).

После обновления проще всего удалить каталог `components/generated/` целиком и перегенерировать (меню `PGDECS: Regenerate Components` или headless-скрипт `tests/run_codegen_headless.gd`).

## 2.1 — Тип компонента: enum вместо Variant.Type (breaking)

`register_component` и `ECSComponentRegistryStrategy.get_components()` используют `ECSComponent.Type` вместо `Variant.Type`.

```gdscript
# было
ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)

# стало
ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)
```

| Было (Variant.Type) | Стало (ECSComponent.Type) |
|---------------------|----------------------------------|
| `TYPE_PACKED_BYTE_ARRAY` | `PACKED_BYTE` |
| `TYPE_PACKED_INT32_ARRAY` | `PACKED_INT32` |
| `TYPE_PACKED_INT64_ARRAY` | `PACKED_INT64` |
| `TYPE_PACKED_FLOAT32_ARRAY` | `PACKED_FLOAT32` |
| `TYPE_PACKED_FLOAT64_ARRAY` | `PACKED_FLOAT64` |
| `TYPE_PACKED_VECTOR2_ARRAY` | `PACKED_VECTOR2` |
| `TYPE_PACKED_VECTOR3_ARRAY` | `PACKED_VECTOR3` |
| `TYPE_PACKED_VECTOR4_ARRAY` | `PACKED_VECTOR4` |
| `TYPE_PACKED_COLOR_ARRAY` | `PACKED_COLOR` |
| `TYPE_PACKED_STRING_ARRAY` | `PACKED_STRING` |
| `TYPE_OBJECT` / `TYPE_ARRAY` (generic Object) | `OBJECT` |

Новые типы (строгие хранилища `Array[T]`): `AABB`, `RECT2`, `QUATERNION`, `BASIS`, `TRANSFORM2D`, `TRANSFORM3D`, `VECTOR2I`, `VECTOR3I`, `VECTOR4I`, `NODE`, `NODE2D`, `NODE3D`, `RESOURCE`, `PACKED_SCENE`, `REF_COUNTED`. См. [OBJECT_COMPONENTS.md](OBJECT_COMPONENTS.md).

`get_components()`:

```gdscript
# было
func get_components() -> Dictionary[int, int]:
	return { Component.POSITION: TYPE_PACKED_VECTOR2_ARRAY }

# стало
func get_components() -> Dictionary[int, ECSComponent.Type]:
	return { Component.POSITION: ECSComponent.Type.PACKED_VECTOR2 }
```

## Текущая модель (два слоя)

| Слой | Методы | Когда |
|---|---|---|
| **Внешний** | `create_entity`, `create_entities`, `destroy_entities`, `precache_archetype` (`Array[int]`) | Игровой код, setup, разовые вызовы |
| **Hot path** | `create_entity_packed`, `create_entities_packed`, `destroy_entities_packed`, `precache_archetype_packed` | Циклы, батчи, command buffer execute |
| **Предефайн** | `prepare_archetype([...])` → `PackedInt64Array` | Один раз в `_setup`, дальше `*_packed` |

## Быстрые замены

```gdscript
# Удобный внешний API
var e := ecs.create_entity([POSITION_ID, HEALTH_ID])
var ids := ecs.create_entities(1000, [POSITION_ID])
ecs.destroy_entities([id_a, id_b])
ecs.precache_archetype([POSITION_ID, HEALTH_ID])

# Hot path (без аллокации Array на каждый вызов)
var player_arch := ecs.prepare_archetype([POSITION_ID, HEALTH_ID])
ecs.create_entity_packed(player_arch)
ecs.create_entities_packed(100, player_arch)
ecs.destroy_entities_packed(survivor_ids)
```

## Историческая заметка

Ранее существовали varargs `create_entity(a, b, c)` — заменены на явный `Array[int]` + внутренний `PackedInt64Array` для предсказуемости типов и hot path.

## Safety refactor (архетипы, query, reset)

| Изменение | Детали |
|---|---|
| Ключи архетипов | Реестр по `PackedInt64Array` component ids, не по `bit_hash()` |
| `ECSManager.reset()` | Уничтожает все сущности и архетипы; `register_component` сохраняется |
| `auto_gc_archetypes` | По умолчанию `true`: GC один раз в конце кадра `ECSWorld._process` |
| `flush_archetype_gc()` | Ручной сброс отложенного GC (бенчмарки без раннера) |
| `get_chunks()` | Pooled views текущего run — **не** кэшировать между вызовами |
| `for_each_chunk()` | Тот же пул; Callable на границе callback — для скриптов/тестов |
| `begin_chunk_run()` | Предпочтительно в ручной итерации; системы используют через `ECSSystemChunkBase` |
| `get_entity_archetype()` | Не кэшировать `ECSArchetype` между кадрами после destroy/GC |

## 2.0 — Bridge layer removed (breaking)

В **PGDECS 2.0** удалён весь bridge-слой. Это осознанный шаг: ядро остаётся SoA + systems + profile; связь с Node/RID/variable data — через **Intent-теги + reference-компоненты (`NODE2D`, `RESOURCE`) и Resource-сервисы** в игровом коде. См. [INTENT_PIPELINE.md](INTENT_PIPELINE.md).

### Удалённые классы

| Категория | Классы |
|-----------|--------|
| Bridge core | `ECSBridgeHost`, `ECSBridgeBackend`, `ECSBridgeRegistry` |
| Systems | `ECSBridgeOrchestratorSystem`, `ECSBridgeSyncSystem` |
| Config | `ECSBridgeRegistryStrategy`, `ECSBridgeBackendStrategy`, `ECSBridgeComponentIds`, `ECSBridgeOrchestratorStrategy`, `ECSBridgeSyncStrategy` |
| ECSWorld API | `get_bridge_registry()`, `set_bridge_registry()` |
| ECSWorldProfile | `bridge_registry_strategy`, `apply_to_world(world, bridge_host)` → `apply_to_world(world)` |

### Быстрая замена

```gdscript
# было (1.x bridge)
profile.bridge_registry_strategy = bridge_strategy
profile.system_strategies = [
    ECSBridgeOrchestratorStrategy.new(),
    ECSBridgeSyncStrategy.new(),
]

# стало (2.0) — игровой код
# Resource-сервисы через @export в ECSSystemStrategy (ExampleEcsDependencies)
# Intent-теги: INTENT_BIND_*, INTENT_RELEASE, INTENT_DESTROY
# Системы: bind → sync → release → destroy sweep
# См. ecs/examples/intent/example_intent_world_profile.gd и INTENT_PIPELINE.md
```

### Таблица: bridge → intent

| 1.x | 2.0 |
|-----|-----|
| `BRIDGE_TYPE` + `BRIDGE_HANDLE` | reference-компонент на домен (`NODE2D`, `NODE`, `RESOURCE`) |
| `TAG_BRIDGE_PENDING_ACQUIRE` | `INTENT_BIND_*` |
| `TAG_BRIDGE_PENDING_RELEASE` | `INTENT_RELEASE` |
| `ECSBridgeOrchestratorSystem` | `ExampleBindIntentSystem` + `ExampleReleaseIntentSystem` |
| `ECSBridgeSyncSystem` | `ExampleNodeSyncSystem` (игра) |
| `bridge_registry_strategy` | `@export dependencies: ExampleEcsDependencies` |

Историческая заметка: в 1.x до bridge существовали `ECSVisual*` / `visual_registry_strategy` — они были удалены ранее.
