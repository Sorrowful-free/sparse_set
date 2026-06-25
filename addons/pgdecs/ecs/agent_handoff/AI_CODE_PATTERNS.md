# Рекомендации для ИИ-агентов (код ECS)

**Обязательно читать перед генерацией систем, spawn/destroy и gameplay-кода.**

Цель: не изобретать API, не смешивать fast-path со structural changes, не вызывать `ECSManager` напрямую там, где нужен command buffer.

**Автоподхват в Cursor (переезжает с аддоном):**
- [`../../AGENTS.md`](../../AGENTS.md)
- [`../../.cursor/rules/pgdecs-ecs-codegen.mdc`](../../.cursor/rules/pgdecs-ecs-codegen.mdc)

См. также: [FRAMEWORK.md](../FRAMEWORK.md), [PERFORMANCE.md](../PERFORMANCE.md), пример [`demo_movement_system.gd`](../examples/demo_movement_system.gd).

---

## 0. Итерация по чанкам и Callable (обязательно для систем)

### Что генерировать

| Контекст | API | Callable? |
|----------|-----|-----------|
| **Система** (`ECSSystemChunkBase`) | Переопределить `process_chunk(chunk, delta)` | **Нет** — раннер вызывает напрямую |
| **Скрипт / тест / one-off** | `query.for_each_chunk(func ...)` или `begin_chunk_run` + цикл | Допустим `for_each_chunk` |
| **WTP в системе** | `use_worker_pool = true` + `parallel_settings` | **Нет** в hot path — `ECSChunkWorkerDispatch.run_chunks_for_system` |

Раннер (`ECSSystemChunkBase.update`) на main thread:

```gdscript
var run_count := _query.begin_chunk_run()
for i in range(run_count):
    process_chunk(_query.get_chunk_at_run_index(i), delta)
```

**Не генерировать** в системах:

```gdscript
# ПЛОХО: Callable в hot path системы
func update(delta):
    _query.for_each_chunk(func(chunk): process_chunk(chunk, delta))

# ПЛОХО: вручную ECSChunkWorkerDispatch в gameplay-системе
ECSChunkWorkerDispatch.run_chunks(...)  # только бенчмарки / низкоуровневые тесты
```

### Пул `ECSQueryChunk` — контракт

- `begin_chunk_run()` / `for_each_chunk` / `collect_chunks(out, true)` / `get_chunks()` — **одни и те же pooled views**.
- Views **инвалидируются** следующим `begin_chunk_run` / `for_each_chunk` на том же `ECSQuery`.
- **Не сохранять** `ECSQueryChunk` между кадрами и между вызовами query.
- Независимые snapshot (редко): `collect_chunks(out, false)` — новый `ECSQueryChunk.new()` на чанк.

### WTP (WorkerThreadPool)

```gdscript
# В _init системы или через ECSChunkSystemStrategy в profile:
use_worker_pool = true
parallel_settings.chunks_per_task = 8          # AUTO: батч чанков на задачу
parallel_settings.min_parallel_tasks = 2       # меньше задач → main thread
parallel_settings.parallel_mode = ECSChunkParallelSettings.ParallelMode.AUTO
# FORCE — тяжёлый process_chunk (pathfinding, физика): min(CPU, chunk_count) задач
```

- При `task_count == 0` (AUTO fallback) — тот же main-loop, **без** dispatch.
- При `task_count > 0` — `run_chunks_for_system(self, chunks, delta, settings)` → прямой `process_chunk`, без lambda.
- В `process_chunk` при WTP: **только чтение/запись значений** — `get_command_buffer()` **запрещён**.

Сравнение с GECS: fair-пара — PGDECS FAST vs GECS column (~10× быстрее PGDECS); WTP GECS быстрее из‑за 1 архетипа vs ~98 чанков — см. [PERFORMANCE.md § PGDECS vs GECS](../PERFORMANCE.md).

---

## 1. Правило выбора API (главное)

| В `process_chunk` система… | Использовать |
|-----------------------------|--------------|
| Только читает/пишет **значения** компонентов, членство чанка не меняет | **Fast-path** |
| **Создаёт/удаляет** сущности, **add/remove** компонентов, нужен **handle** | **Slot API** + `get_command_buffer()` |

**Не смешивать** в одном проходе: fast-path буферы + `get_command_buffer()` без необходимости. Если есть spawn/destroy — итерация по `get_dense_entities()`, не только по `get_dense_slots()`.

---

## 2. Итерация: fast-path (канон)

Использовать для движения, физики, AI **без** structural changes в том же `process_chunk`.

```gdscript
func process_chunk(chunk: ECSQueryChunk, delta: float) -> void:
	var pos_chunk := chunk.get_component_chunk(POSITION_ID) as ECSComponentVector2ArrayChunk
	var vel_chunk := chunk.get_component_chunk(VELOCITY_ID) as ECSComponentFloat32ArrayChunk
	if pos_chunk == null or vel_chunk == null:
		return

	var slots: PackedInt32Array = chunk.get_dense_slots()
	var pos_buf: PackedVector2Array = pos_chunk.get_values_buffer()
	var vel_buf: PackedFloat32Array = vel_chunk.get_values_buffer()

	for i in range(chunk.get_entity_count()):
		var slot: int = slots[i]
		pos_chunk.set_value_at_slot(
			slot,
			pos_buf[slot] + Vector2(vel_buf[slot] * delta, 0.0)
		)
```

**Обязательно:**
- `set_value_at_slot` для записи (не голая запись в `get_values_buffer()[slot]`, если включён `change_detection`).
- Базовый класс: `ECSSystemChunkBase`, query в `_build_query()`.

**Запрещено в fast-path проходе:**
- `ecs.create_entity` / `destroy_entity` / `add_component` / `remove_component`
- `get_command_buffer()` при `use_worker_pool == true`

---

## 3. Итерация + structural changes (канон)

```gdscript
func process_chunk(chunk: ECSQueryChunk, _delta: float) -> void:
	var health_chunk := chunk.get_component_chunk(HEALTH_ID) as ECSComponentInt32ArrayChunk
	if health_chunk == null:
		return

	var buf := get_command_buffer()
	var dense: PackedInt64Array = chunk.get_dense_entities()

	for i in range(chunk.get_entity_count()):
		var entity_id: int = dense[i]
		var slot: int = ECSEntityIdsUtils.slot_from_handle(entity_id)
		if health_chunk.get_value_at_slot(slot) <= 0:
			buf.destroy_entity(entity_id)
```

**Обязательно:**
- handle = `dense[i]` или `chunk.get_entity_id_at(i)`
- slot = `ECSEntityIdsUtils.slot_from_handle(entity_id)` для чтения SoA в чанке

---

## 4. Command buffer (канон)

Буфер есть у каждой системы: `get_command_buffer()`. **`execute()` вызывает `ECSSystemRunner` после `update()` каждой системы** (режим `PER_SYSTEM`, default) — в системе вручную `execute()` не вызывать (кроме unit-тестов).

```gdscript
var buf := get_command_buffer()

# Одна сущность — возвращает временный id (< 0)
var temp_id: int = buf.create_entity([POSITION_ID, HEALTH_ID])

# Пакет
var temp_ids: PackedInt64Array = buf.create_entities(10, [POSITION_ID, VELOCITY_ID])

buf.add_component(entity_or_temp_id, HEALTH_ID)
buf.remove_component(entity_or_temp_id, HEALTH_ID)
buf.destroy_entity(entity_or_temp_id)
buf.destroy_entities([id_a, id_b])
```

**Временные id:**
- `create_entity` / `create_entities` → отрицательные id до `execute()`
- На temp id можно `add_component` / `destroy_entity` в том же кадре
- Coalescing: create + destroy temp в одном кадре → сущность не появится

**Когда сущность видна в query:**
- После `execute()` **предыдущих** систем в том же `run_group` (PER_SYSTEM flush)
- Не в середине `process_chunk` той же системы до её собственного flush

| Место | API |
|-------|-----|
| Bootstrap, тесты, код вне систем | `ecs.create_entity_packed()` / `create_entities_packed()` — сразу real id |
| Внутри `ECSSystemBase.update` / `process_chunk` | только `get_command_buffer()` |

---

## 5. Инициализация компонентов новых сущностей

**Не генерировать** код, который после `buf.create_entity` в `process_chunk` сразу пишет в компоненты по temp id через `ecs.get_component_array` — real id ещё нет.

Допустимые паттерны:

1. **Spawn вне hot loop** (после `runner.run`): gameplay вызывает buffer → `run` → `set_component(real_id, value)`.
2. **Отдельная система позже в кадре** — только если значения дефолтные; кастомные поля — после execute.
3. **Две фазы между кадрами**: кадр N — create; кадр N+1 — init по query «без флага initialized».

---

## 6. Антипаттерны (не генерировать)

```gdscript
# ПЛОХО: create напрямую в process_chunk
func process_chunk(chunk, delta):
	ecs.create_entity_packed(...)  # ЗАПРЕЩЕНО

# ПЛОХО: get_entity_ids() каждый кадр вместо chunk iteration
for id in query.get_entity_ids():
	...

# ПЛОХО: for_each_chunk внутри ECSSystemChunkBase вместо process_chunk override
func update(delta):
	query.for_each_chunk(func(c): ...)  # раннер уже итерирует — переопредели process_chunk

# ПЛОХО: кэшировать ECSQueryChunk между кадрами
var saved_chunk: ECSQueryChunk = query.get_chunk_at_run_index(0)  # инвалидируется на следующем begin_chunk_run

# ПЛОХО: execute() в системе при нормальном runner
func process_chunk(...):
	get_command_buffer().create_entity(...)
	get_command_buffer().execute()  # только в тестах

# ПЛОХО: worker pool + command buffer
use_worker_pool = true
func process_chunk(...):
	get_command_buffer().destroy_entity(...)  # ЗАПРЕЩЕНО

# WTP: parallel_settings на системе или ECSChunkSystemStrategy в profile
# AUTO (лёгкое) — chunks_per_task=8, fallback если задач < 2
# FORCE (тяжёлое pathfinding/физика) — parallel_mode = FORCE
use_worker_pool = true
parallel_settings.parallel_mode = ECSChunkParallelSettings.ParallelMode.FORCE

# ПЛОХО: смешать visual mirror / дублировать handle вне SoA
# handle/type только в компонентах VISUAL_* + registry.release_entity перед destroy
```

---

## 6b. Entity blueprint (канон)

Наследуй [`ECSEntityBlueprint`](../config/ecs_entity_blueprint.gd) в игре; component id — **те же int**, что в enum схемы (`ECSComponentRegistryStrategy`).

**Spawn и параметры — только через command buffer** (`create` + `set_component_value` в одном буфере).

```gdscript
class_name ZombieBlueprint extends ECSEntityBlueprint

@export var base_health: int = 50
@export var spawn_radius: float = 120.0

func build_component_ids() -> PackedInt64Array:
    return PackedInt64Array([
        GameComponents.POSITION,
        GameComponents.HEALTH,
    ])

func apply_defaults(buf: ECSCommandBuffer, entity_id: int) -> void:
    buf.set_component_value(entity_id, GameComponents.HEALTH, base_health)

func apply_instance(buf: ECSCommandBuffer, entity_id: int, _index: int) -> void:
    apply_defaults(buf, entity_id)
    buf.set_component_value(entity_id, GameComponents.POSITION, _random_point_in_radius(spawn_radius))

# Толпа: один буфер — create batch + set на каждый temp id
func spawn_horde(buf: ECSCommandBuffer, count: int) -> PackedInt64Array:
    return spawn_batch(buf, count)
```

| Spawn | API |
|-------|-----|
| Одна сущность | `spawn_one(buf)` → `runner.run()` или `buf.execute()` |
| Толпа / batch | `spawn_batch(buf, count)` — create + `apply_instance` на temp ids |
| Bootstrap | отдельный `ECSCommandBuffer` + `execute()` после spawn |
| Из системы | `spawn_batch(get_command_buffer(), n)` — **не** вызывать `execute()` в системе |

```gdscript
# ПЛОХО: прямой create / set_component в gameplay
ecs.create_entity_packed(...)
health.set_component(entity_id, 50)

# ПЛОХО: spawn без буфера
blueprint.spawn_immediate(ecs)  # удалено — только buffer
```

Эталон: [`example_mover_blueprint.gd`](../examples/example_mover_blueprint.gd).

---

## 7. Bootstrap мира (не путать с spawn)

```gdscript
# Profile — один раз
world.apply_profile(profile)  # повторный вызов игнорируется

# Компоненты: одна ECSComponentRegistryStrategy на profile
profile.component_registry_strategy = MyComponentsStrategy.new()

# Bridge: bridge_registry_strategy (component_ids + backend_strategies внутри)
var bridge := ECSBridgeRegistryStrategy.new()
bridge.component_ids = GameBridgeComponentIds.new()
bridge.backend_strategies = [MyUnitsBridgeBackendStrategy.new()]
profile.bridge_registry_strategy = bridge
profile.system_strategies.append(ECSBridgeOrchestratorStrategy.new())
profile.system_strategies.append(ECSBridgeSyncStrategy.new())

# Spawn: blueprint через command buffer
var buf := ECSCommandBuffer.new(world.get_ecs_manager())
var mover := ExampleMoverBlueprint.new()
mover.spawn_one(buf)
buf.execute()
```

---

## 8. Visual (редкие сущности)

```gdscript
# После execute / когда есть real entity_id:
var handle := registry.acquire(visual_type, entity_id, ecs)
types.set_component(entity_id, visual_type)
handles.set_component(entity_id, handle)

# Destroy:
registry.release_entity(entity_id, ecs)
buf.destroy_entity(entity_id)  # или ecs.destroy_entity вне process_chunk
```

Slot API на spawn достаточен; chunk-based visual bind в фреймворке **не требуется**.

---

## 9. Чеклист перед сдачей кода

- [ ] Chunk-система наследует `ECSSystemChunkBase` и переопределяет `process_chunk`, **не** `for_each_chunk` в `update`
- [ ] Нет сохранения `ECSQueryChunk` между кадрами / между `begin_chunk_run`
- [ ] Система с structural changes использует `get_command_buffer()`, не `ecs.create_*` / `destroy_*` в `process_chunk`
- [ ] Система только с мутацией значений — fast-path, образец как `DemoMovementSystem`
- [ ] Нет ручного `buf.execute()` в production-системах
- [ ] Нет `get_entity_ids()` в hot loop без причины
- [ ] `apply_profile` не вызывается дважды в одном lifecycle (demo: `bootstrap` проверяет `is_profile_applied()`)
- [ ] Unit gate: `run_composer_gates_headless.gd` — `failed: 0`

---

## 10. Ссылки на эталонный код

| Что | Файл |
|-----|------|
| Fast-path движение | [`demo_movement_system.gd`](../examples/demo_movement_system.gd) |
| Chunk base + WTP | [`ecs_system_chunk_base.gd`](../systems/ecs_system_chunk_base.gd) |
| Query chunk run API | [`ecs_query.gd`](../queries/ecs_query.gd) (`begin_chunk_run`) |
| WTP dispatch | [`ecs_chunk_worker_dispatch.gd`](../systems/ecs_chunk_worker_dispatch.gd) |
| Command buffer тесты | [`ecs_command_buffer_test.gd`](../tests/unit/ecs_command_buffer_test.gd) |
| Profile / strategies | [`ecs_world_profile.gd`](../config/ecs_world_profile.gd) |
| Entity blueprint | [`ecs_entity_blueprint.gd`](../config/ecs_entity_blueprint.gd), [`example_mover_blueprint.gd`](../examples/example_mover_blueprint.gd) |
| Runner порядок | [`ecs_system_runner.gd`](../systems/ecs_system_runner.gd) |
