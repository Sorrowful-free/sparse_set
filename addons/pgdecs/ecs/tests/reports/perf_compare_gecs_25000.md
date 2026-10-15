# Perf 25000: PGDECS vs GECS (median ×5)

| Источник | Папка |
|---|---|
| PGDECS + GECS | `pgdecs/ecs/tests/reports/multirun_compare_gecs/` (run_1..5.log, gitignored) |

Шкала: **iterations=25000**, query-метрики — ×100 прогонов над миром 25k сущностей.
Раннер: `addons/gecs/tests/run_compare_frameworks_headless.tscn` (оба фреймворка в одном прогоне).

Окружение: Godot 4.7.2 headless, AMD Ryzen 7 7735HS, Linux 7.2.9 (CachyOS).

## Сводная таблица (median, s)

| Бенчмарк | PGDECS | GECS | PGDECS/GECS |
|---|---:|---:|---:|
| create_entity | 0.162 | 2.427 | **15.0×** |
| destroy_entity | 0.146 | 0.607 | **4.2×** |
| create_entities batch | 0.075 | 2.315 | **30.9×** |
| destroy_entities batch | 0.097 | 0.446 | **4.6×** |
| query.get_entity_ids | 0.068 | ~0 | — |
| query.for_each_chunk iterate | 0.010 | ~0 | — |
| iterate e+c FAST (dense_slots+buffers) | 0.209 | 2.411 | **11.5×** |
| iterate e+c slot API (unfair pair) | 1.887 | 2.411 | **1.3×** |
| iterate e+c WorkerThreadPool | 0.017 | 0.002 | GECS 8.5× |
| for_each_chunk WorkerThreadPool | 0.017 | 0.002 | GECS 8.5× |
| add/remove_component | 0.126 | 0.497 | **3.9×** |
| command_buffer execute | 0.010 | 0.025 | **2.5×** |
| command_buffer coalescing frame | 0.023 | 0.180 | **7.8×** |
| system change_detection steady | 0.040 | 2.418 | **60.5×** |
| system scattered ON / OFF | 1.436 / 1.398 | 2.508† | **1.8×** |
| system hot-chunks ON / OFF | 0.088 / 1.348 | 2.441† | **27.7× / 1.8×** |

† GECS: `system process scattered` / `system process hot-chunks` — dirty-skip чанков нет, всегда полный обход.

## Оговорки

- **WTP-метрики и `get_entity_ids`/`for_each_chunk` — не apples-to-apples.** Мир GECS в бенчмарке — один архетип: `archetypes()`/`execute()` и одна WTP-задача почти бесплатны. PGDECS раскладывает те же 25k в ~98 архетип-чанков и батчит их в ~13 WTP-задач (AUTO).
- **Компоненты разные:** PGDECS — `Vector2`/`int32` в packed SoA-буферах; GECS — `Resource`-компоненты (`BenchPosition`, `BenchHealth`).
- **Slot API vs column iterate** — заведомо нечестная пара (handle/slot на каждую сущность), оставлена для справки.

## Выводы

1. PGDECS **4–31×** быстрее на structural ops (create/destroy/batch).
2. Fast-path итерация **~11.5×** быстрее GECS column iterate.
3. Change detection — главный выигрыш: steady-кадр без записей **~60×** (PGDECS пропускает чистые чанки), hot-chunks ON **~28×**.
4. На scattered-записях (touch почти всех чанков) преимущество сжимается до **~1.8×**.
