# Тесты ECS

## Юнит-тесты

Запуск из редактора Godot: **Project → Tools → Run Unit Tests** (нужно один раз назначить скрипт `ecs/tests/run_unit_tests.gd` как EditorScript) или открыть скрипт `run_unit_tests.gd` и нажать **Run** в панели редактора.

Или из консоли (если есть headless):  
`godot -s res://ecs/tests/run_unit_tests.gd`

Тесты:
- `unit/entity_ids_utils_test.gd` — индексы чанков и слотов
- `unit/entity_ids_pool_test.gd` — пул ID (выдача и повторное использование)
- `unit/archetype_test.gd` — архетип (add/has/remove, несколько чанков)
- `unit/ecs_manager_test.gd` — создание/удаление сущностей, add/remove компонентов, set/get, батчи
- `unit/query_test.gd` — Query (with/without, get_entity_ids)
- `unit/command_buffer_test.gd` — отложенные команды и execute
- `unit/system_runner_test.gd` — SystemRunner (update, execute command buffer)

## Тесты производительности

Запуск: открыть `ecs/tests/run_performance_tests.gd` в редакторе и нажать **Run** (EditorScript).

Бенчмарки:
- create_entity × N
- destroy_entity × N
- create_entities(batch) × несколько батчей
- destroy_entities (один батч)
- query.get_entity_ids() при большом мире
- add_component + remove_component в цикле
- command_buffer.execute() с накопленными create_entity

Количество итераций по умолчанию: 10 000 (в `RunPerformanceTests` можно изменить).
