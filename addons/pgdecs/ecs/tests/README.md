# Тесты ECS

## Юнит-тесты (GUT)

Юнит-тесты используют [GUT](https://github.com/bitwes/Gut) (`addons/gut/`). Конфигурация: `.gutconfig.json` (директория `ecs/tests/unit`, суффикс `*_test.gd`).

### Редактор

- Панель **GUT** внизу редактора → Run All.
- Или **Project → Tools → Run Unit Tests** (`ecs/tests/run_unit_tests.gd` как EditorScript) — запускает GUT headless.

### Консоль (headless)

При первом запуске или после добавления `class_name` выполните импорт:

```powershell
$godot = (Get-Command godot -ErrorAction SilentlyContinue).Source
if (-not $godot) { $godot = "godot" }
& $godot --headless --path . --import
& $godot --headless --path . --script res://addons/pgdecs/ecs/tests/run_composer_gates_headless.gd
```

Альтернатива-обёртка: `ecs/tests/run_unit_tests_headless.gd` (GUT CLI напрямую).

Тесты в `unit/`:
- `unit/ecs_archetype_key_test.gd` — канонические ключи архетипов, bit_equals
- `unit/ecs_archetype_gc_test.gd` — eviction архетипов, reset, churn
- `unit/ecs_entity_ids_utils_test.gd` — индексы чанков и слотов
- `unit/ecs_entity_ids_pool_test.gd` — пул ID (генерации, реюз, защита от double-free)
- `unit/ecs_archetype_test.gd` — архетип (add/has/remove, несколько чанков)
- `unit/ecs_bit_mask_test.gd` — ECSBitMask (set/test/match/hash, bounds-guard)
- `unit/ecs_component_factory_test.gd` — ECSComponentFactory
- `unit/ecs_component_array_test.gd` — компоненты/чанки (add/get/set/remove, батчи, границы)
- `unit/ecs_manager_test.gd` — создание/удаление сущностей, add/remove компонентов, set/get, батчи
- `unit/ecs_manager_archetype_transition_test.gd` — нормализация component_ids, кэш переходов архетипов
- `unit/ecs_query_test.gd` — Query (with/without, get_entity_ids, get_chunks)
- `unit/ecs_query_chunk_test.gd` — ECSQueryChunk (get_component_chunk по chunk_index)
- `unit/ecs_world_state_test.gd` — валидность состояния мира
- `unit/ecs_command_buffer_test.gd` — отложенные команды и execute
- `unit/ecs_system_runner_test.gd` — SystemRunner, per-system flush
- `unit/ecs_system_scheduler_test.gd` — ECSSystemScheduler
- `unit/ecs_system_group_config_test.gd` — group config preset
- `unit/ecs_system_chunk_base_test.gd` — ECSSystemChunkBase (single-thread + worker pool)
- `unit/ecs_regression_test.gd` — регрессии (without > max component, stale handle, add/remove)
- `unit/ecs_archetype_chunk_test.gd` — dense add/remove, swap-remove, slots
- `unit/ecs_membership_test.gd` — has_component только через archetype
- `unit/ecs_dense_iteration_test.gd` — count O(alive), dense vs query ids
- `unit/ecs_entity_blueprint_test.gd` — blueprint spawn, `build_default_values`, `apply_defaults`, node bindings (`build_node_bindings`, `spawn_*_bound`)
- `unit/ecs_intent_pipeline_test.gd` — smoke lazy-пути: spawn → bind → sync → release → destroy sweep
- `unit/ecs_world_demo_test.gd` — smoke `ECSDemoWorld.bootstrap()` и движение (simulation / `_physics_process`)
- `unit/ecs_world_profile_test.gd` — profile strategies, `reset_world`, повторный apply

CI: `.github/workflows/ecs-tests.yml` (Godot 4.7 + `run_composer_gates_headless.gd`).

## Composer quality gates

См. [`agent_handoff/QUALITY_GATES.md`](../agent_handoff/QUALITY_GATES.md).

```powershell
$godot = (Get-Command godot -ErrorAction SilentlyContinue).Source
if (-not $godot) { $godot = "godot" }
& $godot --headless --path . --script res://addons/pgdecs/ecs/tests/run_composer_gates_headless.gd
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
- `query iterate e+c begin_chunk_run main` (index loop без Callable — baseline для систем)
- `query iterate entities+components [slot API]` — slow path (handle/slot; для command buffer / структурных операций)
- `query iterate entities+components FAST [dense_slots+buffers]` — fast path (сравнивать с GECS column iterate)
- WorkerThreadPool варианты (`ECSChunkWorkerDispatch` AUTO: ~CPU batched tasks, не 1:1 chunk)
- `add/remove_component`
- `command_buffer execute` (1000× create)
- `command_buffer coalescing frame` (шумный deferred-кадр)
- `system change_detection steady` (skip-clean без записей)
- `system change_detection scattered/hot-chunks ON/OFF` (размазанные vs локальные изменения)

Только change-detection (25000, без полного perf-suite):

```powershell
& "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path . --script res://addons/pgdecs/ecs/tests/run_change_detection_hot_perf_headless.gd
```

Сравнение WTP-политик (AUTO cpt=8 vs cpt=256 main-fallback vs for_each_chunk / begin_chunk_run):

```powershell
& godot --headless --path . --script res://addons/pgdecs/ecs/tests/run_wtp_policy_compare_headless.gd
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
