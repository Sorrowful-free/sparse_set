# PGDECS Refactor Report (Baseline vs After)

Сырые логи:
- `baseline_unit.log`
- `baseline_performance.log`
- `after_unit.log`
- `after_performance.log`

## Unit tests

- Baseline: `passed: 522 / failed: 0`
- After: `passed: 534 / failed: 0`
- Изменение: +12 новых проверок (инварианты O(1)-удаления, дедуп/стабилизация query builder, hash invalidation).

## Performance (iterations = 25000)

| Benchmark | Baseline (s) | After (s) | Delta |
|---|---:|---:|---:|
| create_entity | 0.298 | 0.259 | -13.1% |
| destroy_entity | 0.219 | 0.166 | -24.2% |
| create_entities batch | 0.102 | 0.103 | +1.0% |
| destroy_entities batch | 0.181 | 0.141 | -22.1% |
| query.get_entity_ids | 0.094 | 0.097 | +3.2% |
| query.get_chunks iterate | 0.022 | 0.012 | -45.5% |
| query iterate entities+components | 3.480 | 3.159 | -9.2% |
| query iterate entities+components WorkerThreadPool | 0.016 | 0.014 | -12.5% |
| query chunks WorkerThreadPool | 0.017 | 0.014 | -17.6% |
| add/remove_component | 0.182 | 0.157 | -13.7% |
| command_buffer execute | 0.014 | 0.014 | 0.0% |

Примечание: результаты сняты на одном хосте без дополнительного warmup/median по нескольким прогонам; для точного профилирования нужны повторные серии.
Дополнительно: в процессе рефакторинга убрана дублирующая регистрация компонента в `ecs_benchmark.gd`, чтобы замеры шли без шумящих `push_error` в `create_entity` сценарии.
