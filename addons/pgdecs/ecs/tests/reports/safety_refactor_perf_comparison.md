# Perf: до GC (HEAD) vs после safety-refactor + deferred GC

Снято на одной машине, Godot 4.7, один прогон на конфигурацию (без multirun/median).

Скрипт: `tests/run_performance_tests_headless.gd`

| Конфигурация | Источник |
|---|---|
| **До GC** | `git HEAD` (`c87f81c`) — bit_hash ключи, плотные chunk-массивы, без GC |
| **После** | Текущий WIP — archetype keys, sparse chunks, deferred `auto_gc_archetypes` |

Логи:
- `perf_before_gc.log`
- `perf_after_deferred_gc_run2.log`

## 25000 итераций (основная шкала)

| Бенчмарк | До GC | После (deferred) | Δ |
|---|---:|---:|---:|
| create_entity | 0.237 s | 0.208 s | **−12%** |
| destroy_entity | 0.140 s | 0.177 s | +26% |
| create_entities batch | 0.086 s | 0.106 s | +23% |
| destroy_entities batch | 0.129 s | 0.155 s | +20% |
| query.get_entity_ids | 0.072 s | 0.075 s | +4% |
| query.for_each_chunk iterate | 0.012 s | 0.013 s | +8% |
| query iterate entities+components | 2.633 s | 2.622 s | **−0.4%** |
| query iterate entities+components FAST | 0.215 s | 0.220 s | +2% |
| add/remove_component | 0.131 s | 0.174 s | +33% |
| command_buffer execute | 0.013 s | 0.011 s | −15% |

## 5000 итераций (smoke)

| Бенчмарк | До GC | После (deferred) |
|---|---:|---:|
| destroy_entity | 0.037 s | 0.038 s |
| add/remove_component | 0.112 s | 0.173 s |
| for_each_chunk iterate | 0.002 s | 0.003 s |

## Выводы

1. **Hot path итерации** (`for_each_chunk`, full component iterate) — на уровне baseline (± несколько %).
2. **destroy / add-remove** дороже baseline из‑за архитектуры safety-refactor (`live_count`, registry, canonical keys), не из‑за flush GC в бенчмарке (бенчмарки не вызывают `flush_archetype_gc()`).
3. **Deferred GC vs immediate GC** (внутри safety-refactor, оценка по сессии): `destroy_entity` 25000 ~0.177 s vs ~0.249 s при eviction на каждый destroy — **~−29%** от отложенного GC.
4. Для точных цифр — multirun (`tests/reports/aggregate_multirun.ps1`, 5 прогонов).

## Примечание по бенчмаркам

`ECSBenchmark.benchmark_destroy_*` вызывает `destroy_entity` напрямую, без `ECSSystemRunner` — eviction не выполняется до `flush_archetype_gc()`. Это отражает **стоимость структурных операций в кадре**, а не end-of-frame GC sweep.
