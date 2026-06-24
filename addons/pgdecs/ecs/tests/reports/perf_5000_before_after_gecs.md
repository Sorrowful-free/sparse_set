# Perf 5000: до GC vs после GC vs GECS (median ×5)

| Источник | Папка |
|---|---|
| До GC | `gecs/tests/reports/multirun_pgdecs/` |
| После GC | `pgdecs/ecs/tests/reports/multirun_post_smart_gc/` |
| GECS | `gecs/tests/reports/multirun_gecs_5000/` (новый прогон ×5) |

Шкала: **iterations=5000**. После GC: runner flush в конце structural-бенчмарков.

## Сводная таблица (median, s)

| Бенчмарк | До GC | После GC | GECS | PGDECS/GECS (после) |
|---|---:|---:|---:|---:|
| create_entity | 0.047 | 0.042 | 0.610 | **14.5×** |
| destroy_entity | 0.028 | 0.039 | 0.100 | **2.6×** |
| create_entities batch | 0.017 | 0.022 | 0.610 | **27.7×** |
| destroy_entities batch | 0.026 | 0.030 | 0.079 | **2.6×** |
| add/remove_component | 0.111 | 0.182 | 0.742 | **4.1×** |
| query.get_entity_ids | 0.015 | 0.016 | ~0 | — |
| query.for_each_chunk | 0.002 | 0.003 | ~0.001 | — |
| query iterate e+c | 0.522 | 0.553 | 0.469 | GECS **1.18×** |
| query e+c WorkerThreadPool | 0.005 | 0.008 | 0.004 | GECS **2.0×** |
| command_buffer execute | 0.012 | 0.012 | 0.036 | **3.0×** |
| command_buffer coalescing | 0.004 | 0.004 | 0.049 | **12.3×** |
| system steady | 0.011 | 0.012 | 0.462 | **38.5×** |
| system scattered OFF | 0.379 | 0.391 | 0.499† | PGDECS **1.28×** |
| system hot-chunks OFF | 0.418 | 0.377 | 0.474† | PGDECS **1.26×** |
| system hot-chunks ON | 0.062 | 0.064 | — | — |

† GECS: `system process scattered` / `system process hot-chunks`.

## Δ после GC vs до GC (5000)

| Бенчмарк | Δ |
|---|---:|
| create_entity | −11% |
| destroy_entity | +39% |
| destroy batch | +15% |
| add/remove | +64% |
| iterate e+c | +6% |

На 5000 overhead GC/refactor на **add/remove** заметнее (+64%), чем на 25000 (+40%): фиксированная стоимость runner flush сильнее на короткой шкале.

## Выводы

1. PGDECS после GC всё ещё **2.6–28×** быстрее GECS на structural ops при 5000.
2. **destroy batch** +15% vs baseline; **destroy single** +39%.
3. **iterate e+c** — GECS чуть быстрее на малом мире (0.47 vs 0.55 s).
4. **change detection** (hot-chunks ON 0.064 s vs GECS full pass ~0.47 s) — **~7×**.
