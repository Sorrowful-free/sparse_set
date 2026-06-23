# Тесты ECS

## Юнит-тесты

Запуск из редактора Godot: **Project → Tools → Run Unit Tests** (нужно один раз назначить скрипт `ecs/tests/run_unit_tests.gd` как EditorScript) или открыть скрипт `run_unit_tests.gd` и нажать **Run** в панели редактора.

Или из консоли (headless). При первом запуске или после добавления `class_name` выполните импорт:

```powershell
& "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path . --import
& "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path . --script res://addons/pgdecs/ecs/tests/run_unit_tests_headless.gd
```

Тесты:
- `unit/ecs_entity_ids_utils_test.gd` — индексы чанков и слотов
- `unit/ecs_entity_ids_pool_test.gd` — пул ID (генерации, реюз, защита от double-free)
- `unit/ecs_archetype_test.gd` — архетип (add/has/remove, несколько чанков)
- `unit/ecs_bit_mask_test.gd` — ECSBitMask (set/test/match/hash, bounds-guard)
- `unit/ecs_sparse_set_test.gd` — ECSSparseSet
- `unit/ecs_component_factory_test.gd` — ECSComponentFactory
- `unit/ecs_component_array_test.gd` — компоненты/чанки (add/get/set/remove, батчи, границы)
- `unit/ecs_manager_test.gd` — создание/удаление сущностей, add/remove компонентов, set/get, батчи
- `unit/ecs_query_test.gd` — Query (with/without, get_entity_ids, get_chunks)
- `unit/ecs_query_chunk_test.gd` — ECSQueryChunk (get_component_chunk по chunk_index)
- `unit/ecs_world_state_test.gd` — валидность состояния мира
- `unit/ecs_command_buffer_test.gd` — отложенные команды и execute
- `unit/ecs_system_runner_test.gd` — SystemRunner
- `unit/ecs_system_chunk_base_test.gd` — ECSSystemChunkBase (single-thread + worker pool)
- `unit/ecs_regression_test.gd` — регрессии (without > max component, stale handle, add/remove)
- `unit/ecs_archetype_chunk_test.gd` — dense add/remove, swap-remove, slots
- `unit/ecs_membership_test.gd` — has_component только через archetype
- `unit/ecs_dense_iteration_test.gd` — count O(alive), dense vs query ids
- `unit/ecs_world_demo_test.gd` — smoke `ECSDemoWorld.bootstrap()`

CI: `.github/workflows/ecs-tests.yml` (best-effort на Windows runner с локальным путём Godot).

## Тесты производительности

Запуск: открыть `ecs/tests/run_performance_tests.gd` в редакторе и нажать **Run** (EditorScript).

Бенчмарки:
- create_entity × N
- destroy_entity × N
- create_entities(batch) × несколько батчей
- destroy_entities (один батч)
- query.get_entity_ids() при большом мире
- add_component + remove_component в цикле
- command_buffer.execute() с накопленными create_entity

Количество итераций по умолчанию: 10 000 (в `RunPerformanceTests` можно изменить).
