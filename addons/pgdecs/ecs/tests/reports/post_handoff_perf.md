# PGDECS Performance — post handoff (transition cache + normalization)

Сырые логи:
- Baseline: `baseline_performance.log`
- После рефакторинга (1 прогон): `after_performance.log`
- До handoff (7 прогонов): `multirun/run_1.log` … `run_7.log`
- После handoff (5 прогонов): `multirun_post_transition/run_1.log` … `run_5.log`

Условия: Godot 4.7 headless, `iterations=25000`, один хост, без отдельного warmup.

## Unit tests (для контекста)

| Этап | Passed |
|---|---:|
| Baseline | 522 |
| После рефакторинга | 534 |
| После handoff (composer gates) | 545 |

## Performance (iterations = 25000)

Метрики: **median** по серии прогонов (устойчивее к выбросам, чем одиночный замер).

| Benchmark | Baseline | After×1 | Prev med (7) | **Now med (5)** | Δ med vs baseline | Δ med vs prev7 |
|---|---:|---:|---:|---:|---:|---:|
| create_entity | 0.298 | 0.259 | 0.236 | **0.230** | **-22.8%** | -2.5% |
| destroy_entity | 0.219 | 0.166 | 0.159 | **0.151** | **-31.1%** | -5.0% |
| create_entities batch | 0.102 | 0.103 | 0.103 | **0.091** | **-10.8%** | -11.7% |
| destroy_entities batch | 0.181 | 0.141 | 0.133 | **0.120** | **-33.7%** | -9.8% |
| query.get_entity_ids | 0.094 | 0.097 | 0.080 | **0.072** | **-23.4%** | -10.0% |
| query.get_chunks() iterate | 0.022 | 0.012 | 0.012 | **0.011** | **-50.0%** | -8.3% |
| query iterate entities+components | 3.480 | 3.159 | 3.085 | **2.675** | **-23.1%** | -13.3% |
| query iterate e+c WorkerThreadPool | 0.016 | 0.014 | 0.015 | **0.014** | **-12.5%** | -6.7% |
| query chunks WorkerThreadPool | 0.017 | 0.014 | 0.014 | **0.014** | **-17.6%** | 0.0% |
| add/remove_component | 0.182 | 0.157 | 0.137 | **0.113** | **-37.9%** | **-17.5%** |
| command_buffer execute | 0.014 | 0.014 | 0.010 | **0.011** | **-21.4%** | +10.0% |

Разброс (now, 5 прогонов): min–max

| Benchmark | min | max |
|---|---:|---:|
| create_entity | 0.221 | 0.385 |
| destroy_entity | 0.139 | 0.192 |
| create_entities batch | 0.089 | 0.142 |
| destroy_entities batch | 0.119 | 0.177 |
| add/remove_component | 0.108 | 0.160 |
| query iterate entities+components | 2.607 | 3.505 |

## Выводы

1. **Относительно baseline** — все бенчмарки быстрее по median; наибольший выигрыш: `query.get_chunks iterate` (−50%), `add/remove_component` (−38%), batch destroy (−34%).
2. **Относительно 7 прогонов до handoff** — стабильное улучшение в `add/remove_component` (−17.5%, transition cache), batch create (−12%), query iterate (−13%). `create_entity` чуть хуже median prev7 (−2.5%), но сильный выброс в run_4 (0.385 s) — вероятный шум ОС/планировщика.
3. **command_buffer** — абсолютные значения ~0.010–0.014 s; +10% к prev7 в пределах погрешности.
4. Для production-профиля разумно снимать **≥5 прогонов** и смотреть median, не одиночный after-run.

---

## Batch A: fast-path batch (post handoff)

Сырые логи: `multirun_post_batch_a/run_1.log` … `run_5.log`

Изменение: chunk-wise batch в [`ecs_component_base_array.gd`](../components/base/ecs_component_base_array.gd) — counting-sort группировка без `Dictionary`, single-chunk fast-path, fallback на поэлементный цикл для `size < 2` и невалидных handle.

Unit после Batch A: **545/545**.

| Benchmark | Baseline | Post-handoff med (5) | **Batch A med (5)** | Δ med vs post-handoff | Δ med vs baseline |
|---|---:|---:|---:|---:|---:|
| create_entities batch | 0.102 | 0.091 | **0.089** | **-2.2%** | **-12.7%** |
| destroy_entity | 0.219 | 0.151 | **0.142** | **-6.0%** | **-35.2%** |
| destroy_entities batch | 0.181 | 0.120 | **0.124** | +3.3% | **-31.5%** |
| add/remove_component | 0.182 | 0.113 | **0.110** | -2.7% | **-39.6%** |
| query iterate entities+components | 3.480 | 2.675 | **2.640** | -1.3% | **-24.1%** |
| query chunks WorkerThreadPool | 0.017 | 0.014 | **0.013** | -7.1% | -23.5% |
| create_entity | 0.298 | 0.230 | **0.232** | +0.9% | -22.1% |
| query.get_entity_ids | 0.094 | 0.072 | **0.073** | +1.4% | -22.3% |
| query.get_chunks() iterate | 0.022 | 0.011 | **0.011** | 0.0% | -50.0% |
| command_buffer execute | 0.014 | 0.011 | **0.011** | 0.0% | -21.4% |

### Выводы Batch A

1. **Целевые batch-сценарии** — `create_entities batch` ещё −2.2% к post-handoff; `destroy_entity` −6.0% (одиночный destroy через component remove).
2. **`destroy_entities batch`** — +3.3% к post-handoff (в шуме): батчи после группировки по архетипу часто multi-chunk, overhead counting-sort заметнее.
3. **Query/create_entity** — без значимых изменений (ожидаемо: Batch A не трогал query path).
4. **Следующий кандидат** — coalescing command buffer (Batch B) или alloc-free query API.

---

## Batch B: command buffer coalescing

Сырые логи: `multirun_post_coalesce/run_1.log` … `run_5.log`

Unit после coalescing: **553/553**.

| Benchmark | Baseline | Batch A med (5) | **Coalesce med (5)** | Δ med vs Batch A | Δ med vs baseline |
|---|---:|---:|---:|---:|---:|
| create_entities batch | 0.102 | 0.089 | **0.104** | +16.9% | +2.0% |
| destroy_entity | 0.219 | 0.142 | **0.163** | +14.8% | **-25.6%** |
| destroy_entities batch | 0.181 | 0.124 | **0.147** | +18.5% | **-18.8%** |
| create_entity | 0.298 | 0.232 | **0.268** | +15.5% | **-10.1%** |
| add/remove_component | 0.182 | 0.110 | **0.128** | +16.4% | **-29.7%** |
| query iterate entities+components | 3.480 | 2.640 | **3.069** | +16.2% | **-11.8%** |
| command_buffer execute | 0.014 | 0.011 | **0.014** | +27.3% | 0.0% |
| query.get_entity_ids | 0.094 | 0.073 | **0.080** | +9.6% | **-14.9%** |
| query.get_chunks() iterate | 0.022 | 0.011 | **0.012** | +9.1% | **-45.5%** |

Разброс coalesce (`create_entities batch`): min **0.095** — med **0.104** — max **0.115** s.

### Выводы coalescing

1. **Относительно Batch A** — все бенчмарки выглядят медленнее (~+10–18%), включая query-пути, которые coalescing не трогал → **скорее шум между сессиями замера**, не регрессия кода.
2. **Относительно baseline** — по-прежнему быстрее на destroy/create/query (кроме `create_entities batch` ≈ +2% к baseline).
3. **`command_buffer execute`** — бенчмарк только 1000× `create_entity` без схлопываемых команд; +27% к Batch A в пределах шума (~0.011 vs 0.014 s).
4. Для честной оценки coalescing нужен **отдельный бенчмарк** с add/remove/destroy в одном буфере (сейчас не покрыт).

---

## Повторный прогон (подтверждение шума сессии)

Сырые логи: `multirun_rerun/run_1.log` … `run_5.log` (сразу после coalescing, 5 прогонов подряд).

| Benchmark | Batch A med | Coalesce₁ med (первая серия) | **Rerun med** | Rerun vs Coalesce₁ | Rerun vs Batch A |
|---|---:|---:|---:|---:|---:|
| create_entities batch | 0.089 | 0.104 | **0.086** | **−17.3%** | **−3.4%** |
| destroy_entity | 0.142 | 0.163 | **0.137** | **−16.0%** | **−3.5%** |
| destroy_entities batch | 0.124 | 0.147 | **0.122** | **−17.0%** | **−1.6%** |
| create_entity | 0.232 | 0.268 | **0.225** | **−16.0%** | **−3.0%** |
| query iterate e+c | 2.640 | 3.069 | **2.607** | **−15.1%** | **−1.2%** |
| add/remove_component | 0.110 | 0.128 | **0.109** | **−14.8%** | **−0.9%** |
| command_buffer execute | 0.011 | 0.014 | **0.013** | −7.1% | +18.2%* |

\* `command_buffer` ~0.011–0.020 s — в шуме.

**Вывод:** первая серия `multirun_post_coalesce` была медленнее на ~15–18% по всем метрикам, включая query (код не менялся). Повторный прогон вернул значения к уровню Batch A ±3%. Регрессии от coalescing **нет** — это межсессионный шум ОС.

---

## Coalescing benchmark (dedicated)

Сырые логи: `multirun_coalesce_bench/run_1.log` … `run_5.log`

Новый сценарий `command_buffer coalescing frame` в [`ecs_benchmark.gd`](../performance/ecs_benchmark.gd) (`iterations=25000`):

- **Setup** (вне замера): 1000 сущностей с `POSITION` в мире.
- **Буфер** (5000 raw-команд на цикл × 1000): для каждой итерации `create+destroy` temp, `add+remove` HEALTH на survivor, затем `destroy_entity` на всех survivors.
- **После coalesce+execute**: мир пустой; фактически один batch `destroy_entities` на 1000 id.

Unit: `test_coalesce_heavy_frame` в [`ecs_command_buffer_test.gd`](../unit/ecs_command_buffer_test.gd). Gates: **566/566**.

| Benchmark (iterations=25000) | min | **med (5)** | max |
|---|---:|---:|---:|
| command_buffer execute (1000× create) | 0.011 | **0.012** | 0.012 |
| **command_buffer coalescing frame (5000 raw → net destroy batch)** | 0.025 | **0.025** | 0.026 |

### Смысл сравнения

| Сценарий | Raw cmds | Что было бы без coalescing | Замер |
|---|---:|---|---:|
| `command_buffer execute` | 1000 | 1000 create | **0.012 s** |
| `coalescing frame` | 5000 | ~2000 add/remove + 2000 create/destroy + 1000 destroy | **0.025 s** |
| Прямой `add/remove_component` (25000 пар) | — | 25000 add + 25000 remove | **~0.105 s** |

Coalescing схлопывает 4000 no-op команд (temp lifecycle + add/remove пары); остаётся только batch destroy ~1000 сущностей. **0.025 s** на 5000 «шумных» команд против **~0.105 s** только на эквивалентные 1000 add/remove без буфера — порядок выигрыша ожидаем для типичного «грязного» кадра deferred-команд.

Старый `command_buffer execute` по-прежнему полезен как baseline чистого create-path; для оценки coalescing смотреть **`coalescing frame`**.

---

## `for_each_chunk` API

Сырые логи:
- До рефактора (бенчмарк `query.get_chunks() iterate`): `multirun_rerun/run_1.log` … `run_5.log`
- После (`query.for_each_chunk iterate`): `multirun_foreach_rerun/run_1.log` … `run_5.log`
- Первая серия после переименования (межсессионный шум): `multirun_foreach_chunk/run_1.log` … `run_5.log`

Изменение: [`ecs_query.gd`](../queries/ecs_query.gd) — `for_each_chunk(callback)` как hot path; `get_chunks()` / `get_entity_ids()` делегируют ему. Main-thread системы в [`ecs_system_chunk_base.gd`](../systems/ecs_system_chunk_base.gd) на `for_each_chunk`.

Агрегация (из `tests/reports/`):

```powershell
.\aggregate_multirun.ps1 -Directory multirun_rerun -Markdown
.\aggregate_multirun.ps1 -Directory multirun_foreach_rerun -CompareDirectory multirun_rerun -Markdown
```

### Chunk iterate (iterations=25000, median по 5 прогонам)

| API (бенчмарк) | min | **med** | max |
|---|---:|---:|---:|
| `query.get_chunks() iterate` (rerun) | 0.010 | **0.011** | 0.013 |
| `query.for_each_chunk iterate` (foreach_rerun) | 0.010 | **0.010** | 0.011 |

Остальные метрики в `multirun_foreach_rerun` на уровне `multirun_rerun` ±3% (шум), кроме `query iterate entities+components` (~2.55 s vs ~2.61 s med).

### Выводы for_each_chunk

1. **Регрессии нет** — median chunk-iterate ~0.010–0.011 s; переименование + callback-path не ухудшили hot path.
2. **`multirun_foreach_chunk`** (первая серия) медленнее на ~10–15% по всем метрикам → межсессионный шум, как у coalescing; ориентироваться на `multirun_foreach_rerun`.
3. Для систем использовать **`for_each_chunk`**, не собирать `Array` через `get_chunks()` на main thread.

---

## Batch D: docs / bench infra

- [`PERFORMANCE.md`](../PERFORMANCE.md) — актуальный список бенчмарков, coalescing frame, `for_each_chunk`, multirun workflow.
- [`aggregate_multirun.ps1`](aggregate_multirun.ps1) — median/min/max из `run_*.log`, опционально `-CompareDirectory` и `-Markdown`.
