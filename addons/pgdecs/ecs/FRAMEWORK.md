# PGDECS — руководство по фреймворку

Data-oriented ECS для Godot 4.x (GDScript). Документ описывает публичный API, внутреннюю модель и правила производительности.

## Содержание

1. [Обзор](#обзор)
2. [Быстрый старт](#быстрый-старт)
3. [Ключевое правило: fast-path vs slot API](#ключевое-правило-fast-path-vs-slot-api)
4. [Сущности и handles](#сущности-и-handles)
5. [Архетипы и чанки](#архетипы-и-чанки)
6. [Компоненты](#компоненты)
7. [ECSManager](#ecsmanager)
8. [Запросы (Query)](#запросы-query)
9. [Системы](#системы)
10. [Command buffer](#command-buffer)
11. [Change detection](#change-detection)
12. [Мир (ECSWorld)](#мир-ecsworld)
13. [Configuration (profile, registry, strategies)](#configuration-profile-registry-strategies)
14. [Visual layer](#visual-layer)
15. [Threading и reentrancy](#threading-и-reentrancy)
16. [Структура каталогов](#структура-каталогов)
17. [См. также](#см-также)

---

## Обзор

PGDECS хранит компоненты в **Structure of Arrays (SoA)** по чанкам фиксированного размера (256 сущностей). Членство сущностей в архетипе — единственный источник правды; компонентные буферы хранят только значения по **slot**.

Типичный цикл кадра:

```
profile.apply_to_world() → каждый кадр: systems.update() → command_buffer.execute()
```

Точка входа в игре — нода [`ECSWorld`](ecs_world.gd) с [`ECSWorldProfile`](config/ecs_world_profile.gd) или прямое использование [`ECSManager`](ecs_manager.gd) + [`ECSSystemRunner`](systems/ecs_system_runner.gd).

**Минимальный путь** (без сцены и profile):

```gdscript
var ecs := ECSManager.new()
ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
var runner := ECSSystemRunner.new()
runner.add_system(MySystem.new(ecs))
runner.run(delta)  # каждый кадр
```

---

## Быстрый старт

```gdscript
var world := ECSDemoWorld.new()
world.bootstrap(1000)
add_child(world)

# Свой профиль:
var profile := ECSWorldProfile.new()
profile.component_registry_strategy = ExampleComponentRegistryStrategy.create_demo()
profile.system_strategies = [DemoMovementStrategy.new()]
world.apply_profile(profile)
# spawn — в коде игры, не в профиле:
var arch := world.get_ecs_manager().prepare_archetype([
    ExampleComponentRegistryStrategy.Component.POSITION,
    ExampleComponentRegistryStrategy.Component.VELOCITY,
])
world.get_ecs_manager().create_entities_packed(100, arch)
```

Демо без сцены: [`examples/demo_world.gd`](examples/demo_world.gd).

---

## Ключевое правило: fast-path vs slot API

**Правило фреймворка для систем:**

| Условие в `process_chunk` | Какой API использовать |
|---|---|
| Система **только читает/меняет значения** компонентов и **не создаёт** новых сущностей (ни spawn, ни destroy, ни add/remove компонентов в этом проходе) | **Fast-path** |
| Система **создаёт или удаляет** сущности, **меняет набор компонентов**, или нужен **handle** сущности (command buffer, внешний lookup) | **Slot API** через handle |

### Fast-path (только мутация значений, стабильное членство)

```gdscript
var slots: PackedInt32Array = chunk.get_dense_slots()
var count: int = chunk.get_entity_count()
var pos_buf: PackedVector2Array = pos_chunk.get_values_buffer()
var health_buf: PackedInt32Array = health_chunk.get_values_buffer()

for i in range(count):
    var slot: int = slots[i]
    var p: Vector2 = pos_buf[slot]
    var h: int = health_buf[slot]
    # запись — через set_value_at_slot (инкрементирует версию для change_detection)
    pos_chunk.set_value_at_slot(slot, p + Vector2(1, 0))
```

- `get_dense_slots()` — плотный `dense_index → slot` в компонентном буфере (синхронизируется при add/remove в archetype chunk).
- `get_values_buffer()` — прямой доступ к `Packed*Array` чанка (без вызова `get_value_at_slot` на каждый элемент).
- Один `slots[i]` общий для всех компонентов query в этом archetype chunk; у каждого `component_id` свой `get_values_buffer()`.

### Slot API (структурные изменения или нужен handle)

```gdscript
var dense: PackedInt64Array = chunk.get_dense_entities()
for i in range(chunk.get_entity_count()):
    var handle: int = dense[i]
    var slot: int = ECSEntityIdsUtils.slot_from_handle(handle)
    pos_chunk.set_value_at_slot(slot, ...)
    get_command_buffer().destroy_entity(handle)  # пример: нужен handle
```

Используйте slot через handle, когда:

- откладываете create/destroy/add/remove через [`ECSCommandBuffer`](ecs_command_buffer.gd);
- читаете компонент по произвольному `entity_id` вне chunk-loop (`get_component(entity_id)`);
- архетип или членство чанка могут измениться в том же логическом проходе.

### Чего не делать

- **Не смешивать** fast-path чтение с прямой записью в `get_values_buffer()[slot]` без `set_value_at_slot`, если включён `change_detection` — версия значений не обновится.
- **Не создавать сущности** внутри `process_chunk` напрямую — только через command buffer в конце кадра; такие системы относятся к slot/handle API.
- **Не вызывать** `get_entity_ids()` каждый кадр, если достаточно chunk-итерации.

Подробности и бенчмарки: [PERFORMANCE.md](PERFORMANCE.md). **ИИ:** [agent_handoff/AI_CODE_PATTERNS.md](agent_handoff/AI_CODE_PATTERNS.md).

---

## Сущности и handles

- Сущность — generational **handle** (`int`): index (low 32) + generation (high 32).
- `ECSEntityIdsPool` выдаёт и переиспользует id; устаревший handle не проходит `is_alive()`.
- Адресация в чанке: `chunk_index = index >> 8`, `slot = index & 0xFF` (`ECSEntityIdsUtils.CHUNK_SIZE == 256`).

```gdscript
ecs.is_alive(handle)
ecs.has_component(handle, POSITION_ID)
ECSEntityIdsUtils.slot_from_handle(handle)
ECSEntityIdsUtils.chunk_index_from_handle(handle)
```

---

## Архетипы и чанки

**Архетип** — уникальный набор component id. Ключ реестра — нормализованный `PackedInt64Array` (не `bit_hash()`). Пустые архетипы и пустые chunk-map записи освобождаются автоматически при destroy / remove_component.

Чанки хранятся в **sparse map** по глобальному `chunk_index` (`entity_index >> 8`): сущность с высоким index не создаёт пустые промежуточные чанки.

`get_entity_archetype()` возвращает ссылку на живой архетип; **не кэшируйте** `ECSArchetype` между кадрами — после eviction ссылка устаревает.

`ECSArchetypeChunk` (членство):

| Поле | Назначение |
|------|------------|
| `_slots[256]` | handle в слоте или tombstone |
| `_dense[0..count)` | плотный список живых handle |
| `_dense_slots[0..count)` | slot для каждого dense_index (fast-path) |
| `_slot_to_dense[256]` | slot → dense_index |
| `_count` | число живых сущностей O(1) |

Удаление — swap-remove в `_dense` за O(1). Итерация query — только по `[0, get_entity_count())`, не scan 256 слотов.

---

## Компоненты

### Регистрация

```gdscript
ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
```

Поддерживаемые типы (codegen): Byte, Int32, Int64, Float32, Float64, Vector2, Vector3, Vector4, Color. См. [`editor/ecs_code_gen.gd`](editor/ecs_code_gen.gd).

### Два уровня API

| Уровень | Класс | Когда |
|---------|-------|-------|
| Мир / сущность | `ECSComponentVector2Array` | `set_component(entity_id, value)` из gameplay вне hot loop |
| Чанк / slot | `ECSComponentVector2ArrayChunk` | системы: `get_value_at_slot`, `set_value_at_slot`, `get_values_buffer()` |

```gdscript
var pos: ECSComponentVector2Array = ecs.get_component_array(POSITION_ID) as ECSComponentVector2Array
pos.set_component(entity_id, Vector2(10, 20))

var chunk: ECSComponentVector2ArrayChunk = query_chunk.get_component_chunk(POSITION_ID)
chunk.get_value_at_slot(slot)
```

### Объектные типы (Node, String)

Не входят в ядро. Паттерн registry + примитивный индекс: [OBJECT_COMPONENTS.md](OBJECT_COMPONENTS.md).

### Tags (marker-компоненты)

Tag — component id **без SoA-хранилища**: членство только в bitmask архетипа. Для фильтрации в query и `has_component`, когда не нужно значение.

```gdscript
ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
ecs.register_tag(ENEMY_TAG_ID)

var e: int = ecs.create_entity_packed(PackedInt64Array([POSITION_ID, ENEMY_TAG_ID]))
ecs.add_component(e, ENEMY_TAG_ID)       # без value
ecs.has_component(e, ENEMY_TAG_ID)       # true
ecs.is_tag(ENEMY_TAG_ID)                 # true
ecs.get_component_array(ENEMY_TAG_ID)    # null

ECSQueryBuilder.new()
    .with_component(POSITION_ID)
    .without_component(ENEMY_TAG_ID)
    .build(ecs)
```

Один id — либо data component (`register_component`), либо tag (`register_tag`). В hot-path систем не вызывайте `get_component_chunk` для tag id — вернётся `null`. Query с `with_component(TAG)` подходит только для фильтрации сущностей, не для итерации значений.

---

## ECSManager

### Два слоя API

| Слой | Примеры | Назначение |
|------|---------|------------|
| Внешний (`Array[int]`) | `create_entity([...])`, `destroy_entities([...])` | setup, разовые вызовы |
| Hot path (`PackedInt64Array`) | `create_entities_packed`, `destroy_entities_packed` | циклы, батчи |
| Предефайн | `prepare_archetype([...])` | один раз в setup, дальше `*_packed` |

### Основные методы

```gdscript
# Жизненный цикл
create_entity / create_entity_packed
create_entities / create_entities_packed
destroy_entity / destroy_entities_packed

# Компоненты
register_component(id, Variant.Type)
register_tag(id)
is_tag(component_id) -> bool
has_component(entity, component_id)
add_component(entity, component_id)
remove_component(entity, component_id)
get_component_array(component_id) -> ECSComponentBaseArray  # null для tag

# Архетипы
precache_archetype / precache_archetype_packed
prepare_archetype([...]) -> PackedInt64Array
get_entity_archetype(entity)
get_archetypes()
count_live_archetypes()
reset()                    # уничтожить все сущности, очистить архетипы; компоненты остаются зарегистрированными
auto_gc_archetypes         # true: GC в конце ECSSystemRunner.run(); false — только вручную
flush_archetype_gc()       # сбросить отложенный GC (пустые архетипы + component chunks)
gc_empty_archetypes()      # только eviction пустых архетипов из registry
is_alive(entity)
```

Миграция и история API: [MIGRATION.md](MIGRATION.md).

---

## Запросы (Query)

```gdscript
var query := ECSQueryBuilder.new()
    .with_component(POSITION_ID)
    .with_component(HEALTH_ID)
    .without_component(DEAD_TAG_ID)
    .build(ecs)
```

### Итерация

| Метод | Назначение |
|-------|------------|
| `begin_chunk_run()` + `get_chunk_at_run_index(i)` | **hot path в системах** — пул без Callable на каждый чанк; views **не сохранять** между вызовами |
| `for_each_chunk(callback)` | удобный API для скриптов/тестов; внутри тот же пул; Callable на границе callback |
| `collect_chunks(out, reuse_snapshot=true)` | по умолчанию pooled views (как `begin_chunk_run`); `reuse_snapshot=false` — независимые `ECSQueryChunk.new()` |
| `get_chunks()` | ссылки на pooled views текущего run; **не** сохранять между вызовами |
| `get_entity_ids()` | плоский список handle; дорого на больших мирах |
| `match(entity_id)` | точечная проверка |

### ECSQueryChunk

```gdscript
chunk.get_entity_count()
chunk.get_dense_entities()      # handle по dense_index
chunk.get_dense_slots()         # slot по dense_index (fast-path)
chunk.get_entity_id_at(i)       # handle по dense_index
chunk.get_component_chunk(id)   # SoA-чанк компонента
chunk.get_structural_version()
chunk.get_component_version(component_id)
```

---

## Системы

### ECSSystemBase

Базовый класс: `update(delta)`, встроенный `ECSCommandBuffer`, доступ к `ECSManager`.

### ECSSystemChunkBase

Рекомендуемая база для hot loop:

1. Переопределить `_build_query()` → `ECSQuery`.
2. Переопределить `process_chunk(chunk, delta)`.
3. Опционально: `change_detection = true`, `use_worker_pool = true` (только чтение в WTP).
4. Настройка WTP per-system: `parallel_settings` ([`ECSChunkParallelSettings`](systems/ecs_chunk_parallel_settings.gd)) или через [`ECSChunkSystemStrategy`](config/ecs_chunk_system_strategy.gd) в profile.

| Поле | Режим | Смысл |
|------|--------|--------|
| `chunks_per_task` | AUTO | Сколько чанков батчить на одну WTP-задачу (default 8) |
| `min_parallel_tasks` | AUTO | Если задач меньше — fallback на main thread (default 2) |
| `parallel_mode` | AUTO / FORCE | AUTO — экономия WTP; FORCE — max параллелизм для тяжёлого `process_chunk` |

[`ECSChunkWorkerDispatch`](systems/ecs_chunk_worker_dispatch.gd) — единая политика: strided WTP или main thread.

**Внутренний поток `update`:**

1. `begin_chunk_run()` — заполняет pooled `ECSQueryChunk` views.
2. Main thread (`use_worker_pool == false`): цикл `get_chunk_at_run_index` → `process_chunk` (без Callable).
3. WTP: при `task_count == 0` — тот же main-loop; при `task_count > 0` — `run_chunks_for_system(self, chunks, delta, settings)` (прямой `process_chunk`, без per-frame lambda).
4. `run_chunks(..., Callable)` — только бенчмарки и низкоуровневые тесты, не gameplay-системы.

```gdscript
class MySystem extends ECSSystemChunkBase:
    func _init(ecs: ECSManager) -> void:
        super(ecs)
        change_detection = true

    func _build_query() -> ECSQuery:
        return ECSQueryBuilder.new().with_component(POSITION_ID).build(get_ecs_manager())

    func process_chunk(chunk: ECSQueryChunk, delta: float) -> void:
        # см. правило fast-path vs slot API выше
        pass
```

### ECSSystemRunner

```gdscript
runner.add_system(system)
runner.run(delta)  # update всех систем → execute всех command buffer → flush_archetype_gc (если auto_gc_archetypes)
```

---

## Command buffer

Отложенные структурные изменения до конца кадра. Coalescing: cancel create+destroy, add+remove, merge destroys.

```gdscript
var buf := get_command_buffer()
buf.create_entity([POSITION_ID, HEALTH_ID])
buf.destroy_entities([id_a, id_b])
buf.add_component(entity, HEALTH_ID)
buf.execute()  # вызывается раннером автоматически
```

Тот же двухслойный API: `Array[int]` и `*_packed`. В `process_chunk` при `use_worker_pool == true` command buffer **не вызывать**.

**Для ИИ-агентов:** канонические примеры и антипаттерны — [agent_handoff/AI_CODE_PATTERNS.md](agent_handoff/AI_CODE_PATTERNS.md). Cursor: [../AGENTS.md](../AGENTS.md), [../.cursor/rules/](../.cursor/README.md).

---

## Change detection

Опционально в `ECSSystemChunkBase`: пропуск `process_chunk` для чанков без структурных и value-изменений с прошлого кадра.

| Версия | Где | Когда растёт |
|--------|-----|--------------|
| Структурная | `ECSArchetypeChunk` | add/remove entity |
| Значений | `ECSComponent*ArrayChunk` | `set_value_at_slot`, batch add/remove |

Включение: `change_detection = true`. Выгодно, когда большинство чанков статичны (типичный игровой паттерн). См. [PERFORMANCE.md](PERFORMANCE.md).

---

## Мир (ECSWorld)

```gdscript
# Нода на сцене
@export var profile: ECSWorldProfile
# Дочерний ECSVisualHost со slots — опционально
```

`ECSWorld` создаёт `ECSManager` и `ECSSystemRunner`, применяет `profile` в `_ready` (один раз), вызывает `run(delta)` и `visual_registry.sync_all` в `_process`. Повторный `apply_profile` игнорируется. `reset_world()` очищает менеджер, системы и visual registry и сбрасывает флаг profile — для reload сцены.

---

## Configuration (profile, registry, strategies)

| Класс | Роль |
|-------|------|
| [`ECSComponentRegistryStrategy`](config/ecs_component_registry_strategy.gd) | `get_tags()` + `get_components()` → `apply_to(ecs)` (одна на profile) |
| [`ECSSystemStrategy`](config/ecs_system_strategy.gd) | `@export` + `create_system(ecs, world)` |
| [`ECSVisualRegistryStrategy`](config/ecs_visual_registry_strategy.gd) | `@export` + `create_registry(ecs, world, host)` |
| [`ECSWorldProfile`](config/ecs_world_profile.gd) | component strategy + visual/system strategies |

Порядок `apply_to_world`: component registry strategy → visual registry strategies → system strategies. `ECSWorld.apply_profile` вызывается **один раз**; повторный вызов игнорируется (debug warning). Передаёт опциональный дочерний `ECSVisualHost` в visual strategies для `require_slot`.

Spawn и precache архетипов — в коде игры (`prepare_archetype` / `create_entities_packed`), не в профиле.

---

## Visual layer

| Класс | Роль |
|-------|------|
| [`ECSVisualHost`](presentation/ecs_visual_host.gd) | якорь visual-сцены, слоты нод (опционально) |
| [`ECSVisualBackend`](presentation/ecs_visual_backend.gd) | один `visual_type` (игра реализует) |
| [`ECSVisualRegistry`](presentation/ecs_visual_registry.gd) | acquire / release_entity / sync_all |

Сцена (Host опционален — только если backends нужны ноды сцены):

```
ECSWorld
└── GameVisualHost       # slots: { &"units": NodePath("UnitsMultiMesh") }
    └── UnitsMultiMesh
```

`ECSWorldProfile.visual_registry_strategy` — подключение registry (одна strategy на profile). Host передаётся в `create_registry` для `require_slot`. Несколько backends — регистрируйте в одном `create_registry` через `registry.register_backend(...)`.

Если `apply_profile` вызван до `add_child(world)` и strategy вернула `null` без host, `ECSWorld._enter_tree()` повторно вызывает `apply_visual_strategy` после появления дочернего `ECSVisualHost`.

Игра — strategy в profile:

```gdscript
class_name UnitsVisualStrategy extends ECSVisualRegistryStrategy

func create_registry(_ecs, world, host) -> ECSVisualRegistry:
    if host == null:
        return null
    var registry := ECSVisualRegistry.new()
    registry.visual_type_component_id = GameComponents.VISUAL_TYPE
    registry.visual_handle_component_id = GameComponents.VISUAL_HANDLE
    var mesh := host.require_slot(&"units") as MultiMeshInstance3D
    registry.register_backend(VisualType.UNITS, UnitsBackend.new(mesh))
    return registry
```

```gdscript
profile.visual_registry_strategy = UnitsVisualStrategy.new()
```

Без Host и без visual strategy — `get_visual_registry()` вернёт `null`, sync не вызывается.

Примитивные компоненты в игре: `VISUAL_TYPE`, `VISUAL_SUBTYPE`, `VISUAL_HANDLE` (`TYPE_PACKED_INT32_ARRAY`). Subtype — свой enum на каждый visual type. LOD swap: `release_entity` → смена `VISUAL_TYPE` → `acquire`. См. [OBJECT_COMPONENTS.md](OBJECT_COMPONENTS.md).

---

## Threading и reentrancy

- Один `ECSManager` — **один поток мутаций** (обычно main thread после `ECSSystemRunner.run`).
- **Не вызывайте** `create_entity`, `destroy_entity`, `add_component`, `remove_component` изнутри `for_each_chunk` / `process_chunk` напрямую — используйте `ECSCommandBuffer`.
- `ECSManager` и `ECSComponentBaseArray` используют **общие scratch-буферы** (`_work_bitmask`, `_destroy_*`, `_batch_*`); вложенные мутации без command buffer в debug могут вызвать `push_error`.
- `for_each_chunk` / `begin_chunk_run` переиспользуют `ECSQueryChunk` из пула; `get_chunks()` и `collect_chunks(out, true)` — те же pooled views, не хранить между кадрами. Независимые snapshot: `collect_chunks(out, false)`.
- `WorkerThreadPool` в `ECSSystemChunkBase` — только чтение/запись значений компонентов, без структурных изменений мира. Политика: `parallel_settings` (AUTO батчинг + fallback; FORCE — max tasks). Не вызывать WTP вручную — используйте `use_worker_pool` на системе.

---

## Структура каталогов

```
addons/pgdecs/ecs/
├── ecs_manager.gd
├── ecs_world.gd
├── config/                 # Strategy (component, visual, system), ECSWorldProfile
├── presentation/           # VisualHost, Backend, Registry
├── ecs_command_buffer.gd
├── entities/
├── components/
├── queries/
├── systems/
├── examples/
└── tests/
```

Именование классов: [NAMING.md](NAMING.md).

---

## См. также

| Документ | Содержание |
|----------|------------|
| [DESIGN.md](DESIGN.md) | архитектурные решения, история фаз |
| [PERFORMANCE.md](PERFORMANCE.md) | оптимизации, бенчмарки, change detection |
| [OBJECT_COMPONENTS.md](OBJECT_COMPONENTS.md) | Node/String через registry |
| [MIGRATION.md](MIGRATION.md) | внешний vs packed API |
| [tests/README.md](tests/README.md) | запуск тестов и perf multirun |
| [agent_handoff/](agent_handoff/README.md) | шаблоны для Composer / CI gates |
