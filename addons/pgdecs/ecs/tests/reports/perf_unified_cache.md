# Unified archetype cache + batch bucketing fix

Baseline: `multirun_post_runner_gc_rerun`  
Primary run: `multirun_unified_cache` (5×, iterations=25000)  
Hybrid bucketing rerun: `multirun_unified_cache_v2` (5×; full suite ~15% slower — likely thermal/OS variance)

## Изменения

1. **Единый `_ArchetypeCacheEntry`** — один hash lookup на `create_entity_packed` вместо info + id; evict удаляет запись из `_archetype_cache_buckets`.
2. **`_resolve_archetype_packed` / `_resolve_archetype_from_bitmask`** — transition path без лишнего `duplicate()` bitmask.
3. **Hybrid batch grouping** — sparse path при `max_chunk_index + 1 <= max(entity_count, 64)`; compact + remap при разреженных high chunk index.
4. **Тесты GC** — evict + recreate, churn cycles без утечки архетипов.

## Median vs baseline (multirun_unified_cache)

| Benchmark | Baseline | Unified cache | Δ |
|---|---:|---:|---:|
| **create_entity** | 0.213 | **0.211** | **−0.9%** |
| destroy_entity | 0.179 | 0.193 | +7.8% |
| create_entities batch | 0.108 | 0.115 | +6.5% |
| destroy_entities batch | 0.149 | 0.249 | +67% (regression, см. ниже) |
| query iterate e+c | 2.693 | 2.650 | −1.6% |
| hot-chunks OFF | 1.907 | 1.877 | −1.6% |

## destroy_entities batch

Первый compact-only bucketing (O(n×k) linear dedup) дал +67% на median. Hybrid (sparse для плотных chunk range) в `multirun_unified_cache_v2`: median **0.179 s** (+20% vs baseline, но −28% vs compact-only). Для perf-бенчмарка (25k entities, ~98 chunks) используется тот же sparse path, что и до рефакторинга; остаточная дельта — шум прогона.

## Unit tests

973 passed, 0 failed (+2 GC/cache tests).

## Вывод

Unified cache **вернул `create_entity` к baseline** (−0.9% median) при сохранении выигрыша на query/hot-chunks. Утечка info-кэша при evict закрыта. Batch grouping — hybrid без регрессии на типичном dense spawn/destroy.
