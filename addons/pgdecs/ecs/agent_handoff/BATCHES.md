# Батчи делегирования (не смешивать в одном запуске)

Один запуск Composer = **ровно один батч**.

## Batch A — Core data-path

**Файлы:**
- [`ecs_archetype_chunk.gd`](../ecs_archetype_chunk.gd)
- [`ecs_component_base_array.gd`](../components/base/ecs_component_base_array.gd)
- [`ecs_bit_mask.gd`](../bit_mask/ecs_bit_mask.gd)
- [`ecs_bit_mask_operations.gd`](../bit_mask/ecs_bit_mask_operations.gd)

**Тип задач:** O(1) структуры, batch hot path, hash-path, без API-ломок.

**Perf gate:** обязателен (`PGDECS_RUN_PERF=1`).

---

## Batch B — API / typing / manager logic

**Файлы:**
- [`ecs_manager.gd`](../ecs_manager.gd)
- [`ecs_command_buffer.gd`](../ecs_command_buffer.gd)
- [`ecs_query_builder.gd`](../queries/ecs_query_builder.gd)
- [`ecs_system_chunk_base.gd`](../systems/ecs_system_chunk_base.gd)

**Тип задач:** strict packed API, нормализация входов, кэши переходов, типизация.

**Perf gate:** если затронут hot path менеджера — да.

---

## Batch C — Codegen / examples

**Файлы:**
- [`ecs_code_gen.gd`](../editor/ecs_code_gen.gd)
- [`editor/templates/`](../editor/templates/)
- [`components/generated/`](../components/generated/)
- [`demo_world.gd`](../examples/demo_world.gd)
- [`README.md`](../../README.md)

**Тип задач:** синхронизация шаблонов, перегенерация, примеры.

**Perf gate:** не требуется.

---

## Batch D — QA / docs / bench / CI

**Файлы:**
- [`tests/`](../tests/)
- [`PERFORMANCE.md`](../PERFORMANCE.md)
- [`DESIGN.md`](../DESIGN.md)
- [`MIGRATION.md`](../MIGRATION.md)
- [`.github/workflows/ecs-tests.yml`](../../../../.github/workflows/ecs-tests.yml)

**Тип задач:** тесты, отчёты, документация, CI.

**Perf gate:** при изменении бенчмарков — да.

**Multirun:** `tests/reports/aggregate_multirun.ps1` — median/min/max из `run_*.log`.

---

## Batch E — World / profile bootstrap

**Файлы:**
- [`ecs_world.gd`](../ecs_world.gd)
- [`ecs_world_profile.gd`](../config/ecs_world_profile.gd)
- [`ecs_component_registry_strategy.gd`](../config/ecs_component_registry_strategy.gd)
- [`ecs_system_strategy.gd`](../config/ecs_system_strategy.gd)
- [`examples/demo_world.gd`](../examples/demo_world.gd)
- [`examples/example_intent_world_profile.gd`](../examples/example_intent_world_profile.gd)
- [`tests/unit/ecs_world_profile_test.gd`](../tests/unit/ecs_world_profile_test.gd)

**Тип задач:** `apply_profile` guard (один раз), intent/services wiring в strategies, debug warnings, примеры.

**Perf gate:** не требуется.

---

## Порядок merge

`A → B → C → D → E` (после каждого батча — unit gate).
