# Perf: destroy buckets (Dictionary) vs предыдущие PGDECS-прогоны

| Источник | Папка |
|---|---|
| **До buckets** (sort_custom) | `multirun_post_smart_gc/` |
| **После buckets** | `multirun_destroy_buckets/` |

Изменение: `destroy_entities_packed` группирует по `archetype_id` через scratch `Dictionary[int, PackedInt64Array]` вместо indirect `sort_custom`. Fast path для одного архетипа сохранён.

Условия: Godot 4.7, median ×5, runner flush в structural-бенчмарках.

## Destroy (median, s)

| Бенчмарк | post_smart_gc | destroy_buckets | Δ |
|---|---:|---:|---:|
| destroy_entities batch (5000) | 0.030 | 0.031 | +3% |
| destroy_entities batch (25000) | 0.148 | 0.148 | **0%** |
| destroy_entity (25000) | 0.192 | 0.188 | **−2%** |

## Прочее (iterations=25000, median, s)

| Бенчмарк | post_smart_gc | destroy_buckets | Δ |
|---|---:|---:|---:|
| add/remove_component | 0.184 | 0.182 | −1% |
| query iterate e+c | 2.592 | 2.605 | +0.5% |
| query e+c FAST | 0.222 | 0.221 | −0.5% |
| query.for_each_chunk | 0.014 | 0.014 | 0% |
| system steady | 0.058 | 0.060 | +3% |
| system hot-chunks ON | 0.128 | 0.132 | +3% |

## Стабильность destroy_buckets (25000)

| Бенчмарк | min | med | max |
|---|---:|---:|---:|
| destroy_entities batch | 0.145 | 0.148 | 0.153 |
| destroy_entity | 0.187 | 0.188 | 0.201 |

## Выводы

1. **Регрессии нет** — destroy batch на 25000 в точности **0.148 s** (паритет с post_smart_gc).
2. На 5000 и по остальным метрикам — **±3%**, в пределах шума между сессиями.
3. Код проще: убран `sort_custom` и `Array[int]` для индексов; multi-archetype path покрыт unit-тестом `test_destroy_entities_multi_archetype`.

Перегенерировать сравнение:

```powershell
cd addons/pgdecs/ecs/tests/reports
.\aggregate_multirun.ps1 -Directory multirun_destroy_buckets -CompareDirectory multirun_post_smart_gc -Iterations 25000 -Markdown
```
