# Рекомендации для ИИ-агентов (код ECS)

**Обязательно читать перед генерацией систем, spawn/destroy и gameplay-кода.**

Цель: не изобретать API, не смешивать fast-path со structural changes, не вызывать `ECSManager` напрямую там, где нужен command buffer.

**Автоподхват в Cursor (переезжает с аддоном):**
- [`../../AGENTS.md`](../../AGENTS.md)
- [`../../.cursor/rules/pgdecs-ecs-codegen.mdc`](../../.cursor/rules/pgdecs-ecs-codegen.mdc)

См. также: [FRAMEWORK.md](../FRAMEWORK.md), [PERFORMANCE.md](../PERFORMANCE.md), пример [`demo_movement_system.gd`](../examples/demo_movement_system.gd).

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

Буфер есть у каждой системы: `get_command_buffer()`. **`execute()` вызывает `ECSSystemRunner` после всех `update()`** — в системе вручную `execute()` не вызывать (кроме unit-тестов).

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
- После `runner.run(delta)` (конец кадра), не в середине `process_chunk` того же прохода

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

# ПЛОХО: execute() в системе при нормальном runner
func process_chunk(...):
	get_command_buffer().create_entity(...)
	get_command_buffer().execute()  # только в тестах

# ПЛОХО: worker pool + command buffer
use_worker_pool = true
func process_chunk(...):
	get_command_buffer().destroy_entity(...)  # ЗАПРЕЩЕНО

# ПЛОХО: смешать visual mirror / дублировать handle вне SoA
# handle/type только в компонентах VISUAL_* + registry.release_entity перед destroy
```

---

## 7. Bootstrap мира (не путать с spawn)

```gdscript
# Profile — один раз
world.apply_profile(profile)  # повторный вызов игнорируется

# Компоненты: одна ECSComponentRegistryStrategy на profile
profile.component_registry_strategy = MyComponentsStrategy.new()

# Visual: только visual_registry_strategies (Host — слоты, не build_registry)
profile.visual_registry_strategies = [MyVisualStrategy.new()]

# Precache/spawn архетипов — код игры, не в profile
var arch := ecs.prepare_archetype([POSITION_ID, VELOCITY_ID])
ecs.create_entities_packed(1000, arch)
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
| Command buffer тесты | [`ecs_command_buffer_test.gd`](../tests/unit/ecs_command_buffer_test.gd) |
| Profile / strategies | [`ecs_world_profile.gd`](../config/ecs_world_profile.gd) |
| Runner порядок | [`ecs_system_runner.gd`](../systems/ecs_system_runner.gd) |
