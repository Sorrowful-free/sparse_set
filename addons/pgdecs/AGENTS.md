# PGDECS — инструкции для ИИ-агентов

Этот файл **переезжает вместе с аддоном**. Cursor подхватывает `AGENTS.md` в подпапках при работе с файлами внутри `addons/pgdecs/`.

**Начинать с [`CHEATSHEET.md`](CHEATSHEET.md)** — рабочий минимум API на одной странице (~1 800 токенов), покрывает ~90% обращений.

**Нужен рабочий образец — смотреть [`ecs/examples/`](ecs/examples/)** (21 файл, ~5 400 токенов на всё): системы, стратегии, блюпринты, реестры компонентов, контейнер зависимостей. Открывать один нужный файл, а не папку.

Файлы ниже — **только если ни шпаргалки, ни примера не хватило**: каждый остаётся в контексте до конца треда.

| Когда шпаргалки не хватило | Файл | Размер |
| --- | --- | --- |
| Паттерны генерации систем | [`ecs/agent_handoff/AI_CODE_PATTERNS.md`](ecs/agent_handoff/AI_CODE_PATTERNS.md) | ~6 100 |
| Архитектура фреймворка | [`ecs/FRAMEWORK.md`](ecs/FRAMEWORK.md) | ~11 600 |
| Intent + reference-компоненты | [`ecs/INTENT_PIPELINE.md`](ecs/INTENT_PIPELINE.md) | — |
| Проектные решения | [`ecs/DESIGN.md`](ecs/DESIGN.md) | ~12 900 |

За один тред открывать **не больше одного** файла из таблицы.

---

## Перед генерацией систем и gameplay-кода

1. Определи режим в `process_chunk` (см. таблицу ниже).
2. **Системы** — `ECSSystemChunkBase` + `process_chunk`; **не** `for_each_chunk` / Callable в hot path. Хуки `process_system` / `build_query` / `process_chunk` — `@abstract`: сигнатуру не менять (опечатка = ошибка парсера, а не тихий no-op).
3. Не вызывай `ecs.create_entity*` / `destroy_*` / `add_component` / `remove_component` внутри `process_chunk` — только `get_command_buffer()`.
4. Не вызывай `buf.execute()` в production-системах (это делает `ECSSystemRunner` после каждой системы, `PER_SYSTEM`).
5. Не сохраняй `ECSQueryChunk` между кадрами (`begin_chunk_run` инвалидирует pooled views).
6. Не используй устаревшее: `InitStrategy`, `RegistryConfig`, `build_registry`, `visual_registry_strategy`, `ECSVisual*`, `ECSBridge*`, `absorb()`, slot-реестры (`ECSNodeRegistry`, `*_SLOT`, `INVALID_SLOT`).
7. `world.apply_profile(profile)` — **один раз** за lifecycle мира.
8. В `_init` chunk-системы `build_query()` вызывается внутри `super(...)`: поля, читаемые в `build_query()`, присваивайте **до** `super(...)` — иначе тихий `null` (парсер не поймает).

---

## Итерация по чанкам

| Кто | Как |
|-----|-----|
| Система | `extends ECSSystemChunkBase` → `build_query()` + `process_chunk(chunk, delta)` |
| Скрипт / тест | `query.for_each_chunk(...)` или `begin_chunk_run()` + `get_chunk_at_run_index(i)` |
| WTP | `use_worker_pool = true`, `parallel_settings`; не вызывать dispatch вручную |

Детали: [`ecs/agent_handoff/AI_CODE_PATTERNS.md` §0](ecs/agent_handoff/AI_CODE_PATTERNS.md).

---

## Fast-path vs command buffer

| В `process_chunk` | API |
|-------------------|-----|
| Только мутация **значений** компонентов | `get_dense_slots()` + `get_values_buffer()` + **`set_value_at_slot`** |
| Spawn/destroy, add/remove компонентов | `get_dense_entities()` + `get_command_buffer()` |
| `use_worker_pool == true` | command buffer **запрещён** |

Эталон fast-path: [`ecs/examples/demo/demo_movement_system.gd`](ecs/examples/demo/demo_movement_system.gd).

---

## Command buffer (кратко)

- `buf.create_entity(...)` → **temp id** (&lt; 0) до `execute()` этой системы.
- Real id и membership в query — после flush **предыдущих** систем в том же `run_group`.
- Bootstrap / тесты **вне** `process_chunk`: `ecs.create_entity_packed()` — сразу real id.
- Перед `destroy_entity`: освободить ссылки (`INTENT_RELEASE` → release system, напр. `pool.release(node)` + `remove_component(NODE)`) или вручную в той же фазе кадра.

## System groups (кратко)

- Группы и расписание — `ECSWorldProfile.system_groups` + `ECSSystemStrategy.run_group`.
- Дефолт: simulation (`_physics_process`), network (20 Hz `_process`), frame (каждый `_process`).
- MANUAL: `world.run_system_group(&"name", delta)`.

---

## Profile / intent / зависимости

- Компоненты: одна `ECSComponentRegistryStrategy` на profile.
- Внешние объекты: **reference-компоненты** (`NODE2D` / `NODE` / `RESOURCE` / `REFCOUNTED`) — ссылка в SoA. Slot-реестры (`*_SLOT` + `ECSNodeRegistry`) удалены.
- **Сервисы** (пул нод, navmesh, `NET_ID`-маппинг): `Resource`; контейнер `ExampleEcsDependencies` / в игре `GameEcsDependencies` или `R_<Module>Dependencies`.
- В **систему** зависимости приходят через `@export` в strategy; **игровой** наследник profile может держать subresource и пробросить в strategies (ядро `ECSWorldProfile` полей dependencies не имеет).
- Lifecycle: intent-теги + bind / sync / release / destroy — [`INTENT_PIPELINE.md`](ecs/INTENT_PIPELINE.md).
- Layout игры: [`FRAMEWORK.md` § структура каталогов](ecs/FRAMEWORK.md#структура-каталогов).

## Entity blueprint

- Наследуй `ECSEntityBlueprint` в игре; `build_component_ids()` — id из твоего enum (int).
- Spawn и параметры — **только** через `ECSCommandBuffer` (`spawn_batch` / `spawn_one` + `set_component_value`); `execute` — runner или bootstrap-буфер.
- Ноды: `build_node_bindings()` → `ECSBlueprintNodeBinding.of(component_id, packed_scene)`; `spawn_one_bound` / `spawn_batch_bound(buf, count, host)` — main thread, **не** в `process_chunk`; `component_id` из bindings добавляются в архетип сами.
- См. [`ecs/examples/schema/example_mover_blueprint.gd`](ecs/examples/schema/example_mover_blueprint.gd) и [`ecs/examples/schema/example_node_binding_blueprint.gd`](ecs/examples/schema/example_node_binding_blueprint.gd).

---

## Валидация после изменений

```powershell
& $godot --headless --path <project_root> --script res://addons/pgdecs/ecs/tests/run_composer_gates_headless.gd
```

Ожидание: `failed: 0`.

---

## Cursor rules в аддоне

Проектные правила лежат в [`addons/pgdecs/.cursor/rules/`](.cursor/rules/) — копируются вместе с аддоном, не требуют `.cursor/` в корне игрового проекта.
