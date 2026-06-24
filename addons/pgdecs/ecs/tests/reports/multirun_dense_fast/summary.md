# PGDECS dense-slots fast iterate — perf (median, 5 runs, iterations=25000)

| Benchmark | med (s) |
|---|---:|
| query iterate entities+components | 3.259 |
| **query iterate entities+components FAST** | **0.260** |
| create_entity | 0.294 |
| destroy_entity | 0.167 |
| add/remove_component | 0.137 |
| system change_detection hot-chunks ON | 0.149 |

FAST vs legacy iterate: **~12.5×** faster (3.259 → 0.260).

Reference GECS median (multirun_gecs): iterate entities+components **2.472 s** — PGDECS FAST is faster.

Structural ops within ~±10% of pre-change baseline (multirun_pgdecs session): no regression blocker.

Unit gate: **873 passed, 0 failed**.
