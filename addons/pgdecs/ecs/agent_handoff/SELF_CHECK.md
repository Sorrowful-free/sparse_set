# Composer Self-Check (перед сдачей)

Composer обязан пройти чеклист **до** финального ответа.

## Scope

- [ ] Изменены только файлы из Task Brief Scope
- [ ] Нет правок в `.cursor/plans/` и посторонних addon-путях
- [ ] Нет «шумового» рефакторинга (переименования, форматирование вне задачи)

## API / typing

- [ ] Нет возврата к varargs (`create_entity(...)`, `precache_archetype(...)`)
- [ ] Публичные методы с return types (`-> void`, `-> int`, …)
- [ ] `Dictionary[int, T]` / `Array[T]` где применимо
- [ ] Если менялся API — обновлены `MIGRATION.md` / `README.md` в том же батче

## Data-path invariants (если Batch A/B)

- [ ] Dense iteration: только `[0, get_entity_count())`
- [ ] Slot API: `ECSEntityIdsUtils.slot_from_handle(handle)`
- [ ] `component_ids` нормализуются (sort + unique) на входе менеджера
- [ ] Переходы архетипов не ломают `has_component` / query membership

## Tests

- [ ] Запущен `run_composer_gates_headless.gd` (unit)
- [ ] Для perf-задач: `PGDECS_RUN_PERF=1` + gates script
- [ ] Новое поведение покрыто unit-тестом в `tests/unit/`

## Handoff

- [ ] Ответ содержит: Changed files / Behavioral impact / Validation evidence / Known risks
