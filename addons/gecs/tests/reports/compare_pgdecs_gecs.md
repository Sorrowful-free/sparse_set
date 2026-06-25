# PGDECS vs GECS — сравнение (iterations=25000)

## Имена метрик

| Метрика | Фреймворк | Путь |
|---|---|---|
| `query iterate entities+components [slot API]` | PGDECS | Slow: handle → slot → `get_value_at_slot` |
| `query iterate entities+components FAST [dense_slots+buffers]` | PGDECS | Fast: `get_dense_slots()` + `get_values_buffer()` |
| `query iterate entities+components [column iterate]` | GECS | Column: `archetype.get_column()` + индекс `i` |

**Честное сравнение hot-path:** PGDECS FAST ↔ GECS column iterate.

**Нечестное (информативное):** PGDECS slot API ↔ GECS column.

## Последний прогон (2025-06, `compare_fresh.log`)

| Benchmark | PGDECS | GECS | Вывод |
|---|---:|---:|---|
| **FAST vs column (fair)** | 0.210 s | 2.290 s | PGDECS **10.9×** faster |
| slot API vs column (unfair) | 2.609 s | 2.290 s | GECS **1.14×** faster |
| WTP e+c (AUTO ~13 tasks) | 0.022 s | 0.002 s | GECS **9.5×** faster* |
| WTP chunk count | 0.020 s | 0.003 s | GECS **7.7×** faster* |
| create_entity | 0.205 s | 2.866 s | PGDECS **14×** faster |
| destroy_entity | 0.204 s | 0.908 s | PGDECS **4.5×** faster |
| add/remove_component | 0.171 s | 0.574 s | PGDECS **3.4×** faster |
| change_detection hot-chunks ON | 0.118 s | 2.300 s† | PGDECS **~19×** faster |
| command_buffer coalescing | 0.028 s | 0.207 s | PGDECS **7.4×** faster |

\* WTP: PGDECS ~98 archetype-chunks → ~13 batched tasks; GECS ~1 archetype → 1 task. Не показатель «лучшего ECS».

† GECS hot-chunks без skip-clean по версиям чанков — другой сценарий.

## WorkerThreadPool

- PGDECS: `ECSChunkWorkerDispatch` + `ECSChunkParallelSettings` (AUTO cpt=8, fallback main).
- Системы: `run_chunks_for_system` — без Callable в hot path.
- Бенчмарки: `run_chunks(..., Callable)` — для сравнения политик.

## Запуск

```powershell
& godot --headless --path . --main-scene res://addons/gecs/tests/run_compare_frameworks_headless.tscn
```

WTP policy (только PGDECS):

```powershell
& godot --headless --path . --script res://addons/pgdecs/ecs/tests/run_wtp_policy_compare_headless.gd
```

Multirun median:

```powershell
cd addons/gecs/tests/reports
.\compare_frameworks.ps1 -PgdecsDirectory multirun_pgdecs -GecsDirectory multirun_gecs -Markdown
```

Скрипт поддерживает legacy-имена метрик (`query iterate entities+components` без суффикса).

## Для ИИ-агентов

- Не оптимизировать PGDECS под «обогнать GECS WTP» на лёгкой работе — структурное ограничение гранулярности.
- Fair regression: FAST vs column, structural ops, change_detection hot-chunks.
- Системы: `ECSSystemChunkBase` + fast-path; см. [`pgdecs/ecs/agent_handoff/AI_CODE_PATTERNS.md`](../../pgdecs/ecs/agent_handoff/AI_CODE_PATTERNS.md).
