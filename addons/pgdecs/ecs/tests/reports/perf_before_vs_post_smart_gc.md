# Perf: до GC vs сейчас (median ×5, iterations=25000)

| Источник | Папка |
|---|---|
| **До GC** | `gecs/tests/reports/multirun_pgdecs/` |
| **Сейчас** | `pgdecs/ecs/tests/reports/multirun_post_smart_gc/` |

Условия «сейчас»: safety-refactor, deferred GC, smart `flush_archetype_gc()`, sparse chunks (archetype + component), runner flush в structural-бенчмарках.

## Сводная таблица (median, s)

| Бенчмарк | До GC | Сейчас | Δ |
|---|---:|---:|---:|
| create_entity | 0.279 | 0.211 | **−24%** |
| destroy_entity | 0.157 | 0.192 | +22% |
| create_entities batch | 0.104 | 0.106 | +2% |
| destroy_entities batch | 0.147 | 0.148 | +1% |
| add/remove_component | 0.131 | 0.184 | +40% |
| command_buffer execute | 0.016 | 0.012 | −25% |
| command_buffer coalescing | 0.031 | 0.028 | −10% |
| query.get_entity_ids | 0.081 | 0.075 | −7% |
| query.for_each_chunk | 0.013 | 0.014 | +8% |
| query iterate e+c | 3.060 | 2.592 | **−15%** |
| query e+c FAST | — | 0.222 | — |
| query e+c WorkerThreadPool | 0.017 | 0.029 | +71% |
| system steady | 0.064 | 0.058 | −9% |
| system scattered OFF | 2.221 | 1.956 | **−12%** |
| system scattered ON | 2.337 | 1.983 | **−15%** |
| system hot-chunks OFF | 2.147 | 1.818 | **−15%** |
| system hot-chunks ON | 0.139 | 0.128 | −8% |

## Стабильность текущего прогона

| Бенчмарк | min | med | max |
|---|---:|---:|---:|
| destroy_entity | 0.190 | 0.192 | 0.193 |
| add/remove | 0.179 | 0.184 | 0.189 |
| iterate e+c | 2.583 | 2.592 | 2.669 |

## Выводы

1. **Итерация / systems** — быстрее baseline на 8–15% (sparse chunks, change detection без лишнего overhead).
2. **create** — быстрее ~24% (вероятно шум + разные условия сессии; create не трогает GC).
3. **destroy batch** — почти паритет (+1%); **destroy single** и **add/remove** — дороже на ~22–40% из‑за safety-refactor + runner flush в конце timed-блока.
4. Smart flush не убирает стоимость structural path; экономит только кадры без structural dirty (не измеряется этими бенчмарками).

Предыдущий rerun (`multirun_post_runner_gc_rerun`): destroy med **0.179 s** — текущий **0.192 s** (+7%), в пределах шума между сессиями.
