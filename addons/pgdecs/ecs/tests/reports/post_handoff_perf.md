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
