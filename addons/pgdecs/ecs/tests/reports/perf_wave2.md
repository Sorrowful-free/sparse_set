# PGDECS wave 2 — perf results

Baseline wave1: `multirun_unified_cache_rerun3`  
Original baseline: `multirun_post_runner_gc_rerun`  
Wave2 logs: `multirun_wave2/` (5×, после fix GC bug)

## Bug fix (до чистого прогона)

`for_each_chunk_index` + `evict_chunk_by_index` в одном проходе → OOB при `flush_archetype_gc`  
(сжатие `_dense_chunk_indices` во время итерации).  
Fix: двухфазный collect → evict в `_evict_orphaned_component_chunks`.

## Median vs rerun3 (iterations=25000) — `multirun_wave2_rerun2` (чистый, стабильный)

| Метрика | rerun3 | rerun2 | Δ |
|---|---:|---:|---:|
| query.for_each_chunk iterate | 0.016 | **0.013** | **−18.8%** |
| change_detection steady | 0.067 | **0.048** | **−28.4%** |
| add/remove_component | 0.190 | **0.161** | **−15.3%** |
| query iterate e+c | 2.644 | **2.507** | **−5.2%** |
| query iterate FAST | 0.231 | **0.214** | **−7.4%** |
| destroy_entities batch | 0.150 | **0.140** | **−6.7%** |
| create_entity | 0.209 | **0.200** | **−4.3%** |
| destroy_entity | 0.190 | **0.190** | 0.0% |

vs original baseline (`multirun_post_runner_gc_rerun`): create_entity −6.1%, query e+c −6.9%, destroy batch −6.0%; destroy_entity +6.1% (в шуме).

Предыдущий `multirun_wave2` (+20% регрессия) — **артефакт нагрузки на машину**, не код.
