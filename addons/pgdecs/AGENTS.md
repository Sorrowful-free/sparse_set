# PGDECS — инструкции для ИИ-агентов

Этот файл **переезжает вместе с аддоном**. Cursor подхватывает `AGENTS.md` в подпапках при работе с файлами внутри `addons/pgdecs/`.

Полные паттерны: [`ecs/agent_handoff/AI_CODE_PATTERNS.md`](ecs/agent_handoff/AI_CODE_PATTERNS.md)  
Архитектура: [`ecs/FRAMEWORK.md`](ecs/FRAMEWORK.md)

---

## Перед генерацией систем и gameplay-кода

1. Определи режим в `process_chunk` (см. таблицу ниже).
2. **Системы** — `ECSSystemChunkBase` + `process_chunk`; **не** `for_each_chunk` / Callable в hot path.
3. Не вызывай `ecs.create_entity*` / `destroy_*` / `add_component` / `remove_component` внутри `process_chunk` — только `get_command_buffer()`.
4. Не вызывай `buf.execute()` в production-системах (это делает `ECSSystemRunner`).
5. Не сохраняй `ECSQueryChunk` между кадрами (`begin_chunk_run` инвалидирует pooled views).
6. Не используй устаревшее: `InitStrategy`, `RegistryConfig`, `build_registry`, `visual_registry_strategies`, `absorb()`, visual dispatcher/mirror.
7. `world.apply_profile(profile)` — **один раз** за lifecycle мира.

---

## Итерация по чанкам

| Кто | Как |
|-----|-----|
| Система | `extends ECSSystemChunkBase` → `_build_query()` + `process_chunk(chunk, delta)` |
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

Эталон fast-path: [`ecs/examples/demo_movement_system.gd`](ecs/examples/demo_movement_system.gd).

---

## Command buffer (кратко)

- `buf.create_entity(...)` → **temp id** (&lt; 0) до конца кадра.
- Real id и membership в query — после `runner.run(delta)`.
- Bootstrap / тесты **вне** `process_chunk`: `ecs.create_entity_packed()` — сразу real id.
- Перед `destroy_entity`: `visual_registry.release_entity(entity_id, ecs)` если был visual.

---

## Visual / profile

- Компоненты: одна `ECSComponentRegistryStrategy` на profile.
- Visual: `visual_registry_strategy` (одна на profile); `ECSVisualHost` — только слоты (`slots`), без `build_registry`.
- `acquire` не пишет в SoA; handle/type пишет игра.

---

## Валидация после изменений

```powershell
& $godot --headless --path <project_root> --script res://addons/pgdecs/ecs/tests/run_composer_gates_headless.gd
```

Ожидание: `failed: 0`.

---

## Cursor rules в аддоне

Проектные правила лежат в [`addons/pgdecs/.cursor/rules/`](.cursor/rules/) — копируются вместе с аддоном, не требуют `.cursor/` в корне игрового проекта.
