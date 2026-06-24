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
- `unit/ecs_manager_archetype_transition_test.gd` — нормализация component_ids, кэш переходов архетипов
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

## Composer quality gates

См. [`agent_handoff/QUALITY_GATES.md`](../agent_handoff/QUALITY_GATES.md).

```powershell
& "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path . --script res://addons/pgdecs/ecs/tests/run_composer_gates_headless.gd
```

## Тесты производительности

Сравнение с GECS: [`../../gecs/tests/README.md`](../../gecs/tests/README.md).

Запуск из редактора: открыть `ecs/tests/run_performance_tests.gd` и нажать **Run** (EditorScript).

Запуск из консоли (headless):

```powershell
& "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path . --script res://addons/pgdecs/ecs/tests/run_performance_tests_headless.gd
```

Headless прогоняет три шкалы: **5000 / 15000 / 25000** итераций. Для отчётов используйте блок `iterations=25000`.

Бенчмарки (см. также [`PERFORMANCE.md`](../PERFORMANCE.md)):

- `create_entity` / `destroy_entity` × N
- `create_entities batch` / `destroy_entities batch`
- `query.get_entity_ids`
- `query.for_each_chunk iterate` (hot path chunk callback)
- `query iterate entities+components` (+ WorkerThreadPool варианты)
- `query.for_each_chunk WorkerThreadPool` (`collect_chunks` + group task)
- `add/remove_component`
- `command_buffer execute` (1000× create)
- `command_buffer coalescing frame` (шумный deferred-кадр)
- `system change_detection steady` (skip-clean без записей)
- `system change_detection scattered/hot-chunks ON/OFF` (размазанные vs локальные изменения)

Только change-detection (25000, без полного perf-suite):

```powershell
& "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path . --script res://addons/pgdecs/ecs/tests/run_change_detection_hot_perf_headless.gd
```

Логи multirun: `tests/reports/multirun_dirty_hot/run_1.log` … `run_5.log`.

После правки шаблона component chunk перегенерируйте типы: `run_codegen_headless.gd`.

### Multirun

Сохраняйте ≥5 прогонов подряд в `tests/reports/multirun_<label>/run_N.log`, сравнивайте **median** в одной сессии.

Агрегация (PowerShell):

```powershell
cd addons/pgdecs/ecs/tests/reports
.\aggregate_multirun.ps1 -Directory multirun_foreach_rerun -Markdown
.\aggregate_multirun.ps1 -Directory multirun_coalesce_bench -CompareDirectory multirun_rerun -Markdown
```

Сводка этапов: [`reports/post_handoff_perf.md`](reports/post_handoff_perf.md).

## Перегенерация компонентного кода

Для синхронизации `components/generated/*` с шаблонами:

```powershell
& "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path . --script res://addons/pgdecs/ecs/tests/run_codegen_headless.gd
```
