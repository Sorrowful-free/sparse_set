# PGDECS vs GECS — median по 5 прогонам (iterations=25000)

Условия: Godot 4.7 headless, одна сессия, median из `multirun_pgdecs/` и `multirun_gecs/`.

Колонка **speedup** — во сколько раз быстрее PGDECS (PGDECS med ÷ GECS med). Значения < 1 — быстрее GECS.

| Benchmark | PGDECS med | GECS med | speedup (PGDECS) |
|---|---:|---:|---:|
| create_entity | 0.279 s | 3.477 s | **12.5×** |
| destroy_entity | 0.157 s | 1.491 s | **9.5×** |
| create_entities batch | 0.104 s | 3.967 s | **38.1×** |
| destroy_entities batch | 0.147 s | 1.204 s | **8.2×** |
| query.get_entity_ids | 0.081 s | ~0 s* | PGDECS измеримо |
| query.for_each_chunk iterate | 0.013 s | ~0 s* | ~ |
| query iterate entities+components | 3.060 s | 2.472 s | GECS **1.24×** |
| query e+c WorkerThreadPool | 0.017 s | 0.003 s | GECS **5.7×** |
| query chunks WorkerThreadPool | 0.016 s | 0.004 s | GECS **4.0×** |
| add/remove_component | 0.131 s | 0.758 s | **5.8×** |
| command_buffer execute | 0.016 s | 0.039 s | **2.4×** |
| command_buffer coalescing frame | 0.031 s | 0.264 s | **8.5×** |
| system steady (no writes) | 0.064 s | 2.464 s | **38.5×** |
| system scattered writes | 2.221 s† | 2.613 s | PGDECS **1.18×** |
| system hot-chunks writes | 2.147 s† | 2.533 s | PGDECS **1.18×** |
| system hot-chunks + change_detection ON | **0.139 s** | 2.533 s | **18.2×** |

\* GECS ниже разрешения `%.3f` — не ноль, просто < 0.0005 s.

† PGDECS `scattered OFF` / `hot-chunks OFF` (полный обход) — аналог GECS `system process scattered/hot-chunks`.

## Выводы

1. **Структурные операции** (create/destroy/batch/add-remove/command buffer) — PGDECS на порядок быстрее: packed IDs + SoA без `Resource`/`Node`.
2. **Тяжёлая итерация по компонентам** — GECS немного быстрее на single-thread query; PGDECS отстаёт на WTP-вариантах (overhead group task vs мало архетипов).
3. **Change detection** — главное преимущество PGDECS: `hot-chunks ON` 0.14 s vs 2.53 s у GECS (полный system pass каждый кадр).
4. **При размазанных записях** (~2% сущностей) — паритет (~2.2 s vs ~2.6 s), GECS без dirty-skip не проигрывает сильно.

Перегенерировать: `.\compare_frameworks.ps1 -PgdecsDirectory multirun_pgdecs -GecsDirectory multirun_gecs -Markdown`
