# PGDECS vs GECS — runner flush GC (median ×5, iterations=25000)

**Актуальные логи PGDECS:** `pgdecs/ecs/tests/reports/multirun_post_runner_gc_rerun/` (перезапуск без нагрузки на машину).

**GECS (без перезапуска):** `gecs/tests/reports/multirun_gecs/`.

Structural-бенчмарки PGDECS: destroy/add-remove/coalescing завершают кадр через `ECSSystemRunner.run()`.

Колонка **× быстрее PGDECS** = GECS med ÷ PGDECS med.

## PGDECS vs GECS (rerun)

| Benchmark | PGDECS med | GECS med | × быстрее PGDECS |
|---|---:|---:|---:|
| create_entity | 0.213 s | 3.477 s | **16.3×** |
| destroy_entity | 0.179 s | 1.491 s | **8.3×** |
| create_entities batch | 0.108 s | 3.967 s | **36.7×** |
| destroy_entities batch | 0.149 s | 1.204 s | **8.1×** |
| query.get_entity_ids | 0.078 s | ~0 s* | PGDECS измеримо |
| query.for_each_chunk iterate | 0.014 s | ~0 s* | ~ |
| query iterate entities+components | 2.693 s | 2.472 s | GECS **1.09×** |
| query e+c WorkerThreadPool | 0.029 s | 0.003 s | GECS **9.7×** |
| add/remove_component | 0.181 s | 0.758 s | **4.2×** |
| command_buffer execute | 0.012 s | 0.039 s | **3.3×** |
| command_buffer coalescing frame | 0.030 s | 0.264 s | **8.8×** |
| system steady (no writes) | 0.061 s | 2.464 s | **40.4×** |
| system scattered OFF | 1.960 s | 2.613 s | PGDECS **1.33×** |
| system hot-chunks OFF | 1.907 s | 2.533 s | PGDECS **1.33×** |
| system hot-chunks ON | **0.132 s** | 2.533 s† | **19.2×** |

\* GECS < 0.0005 s при `%.3f`. † GECS hot-chunks без change_detection ≈ PGDECS `hot-chunks OFF`.

## Стабильность rerun (min–max узкий)

| Benchmark | med | min | max |
|---|---:|---:|---:|
| destroy_entity | 0.179 | 0.177 | 0.181 |
| destroy_entities batch | 0.149 | 0.148 | 0.150 |
| add/remove_component | 0.181 | 0.175 | 0.186 |

Предыдущая сессия (`multirun_post_runner_gc`) давала destroy med **0.219** (max 0.286) — похоже на фоновую нагрузку.

## PGDECS: до safety-refactor vs rerun

Источник «до»: `gecs/tests/reports/multirun_pgdecs/`.

| Benchmark | старый PGDECS | rerun (runner GC) | Δ |
|---|---:|---:|---:|
| destroy_entity | 0.157 s | 0.179 s | +14% |
| destroy_entities batch | 0.147 s | 0.149 s | +1% |
| add/remove_component | 0.131 s | 0.181 s | +38% |
| query iterate e+c | 3.060 s | 2.693 s | **−12%** |
| hot-chunks ON | 0.139 s | 0.132 s | −5% |

Перегенерировать:

```powershell
cd addons\gecs\tests\reports
.\compare_frameworks.ps1 -PgdecsDirectory ..\..\..\pgdecs\ecs\tests\reports\multirun_post_runner_gc_rerun -GecsDirectory multirun_gecs -Markdown
```
