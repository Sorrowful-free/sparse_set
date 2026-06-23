# Agent Handoff (Composer)

Документация для делегирования задач модели **Composer** в Cursor с минимумом последующих правок.

## Быстрый старт

1. Выбери **один** батч: [`BATCHES.md`](BATCHES.md)
2. Заполни [`TASK_BRIEF_TEMPLATE.md`](TASK_BRIEF_TEMPLATE.md) и вставь в промпт Composer
3. После работы — [`SELF_CHECK.md`](SELF_CHECK.md)
4. Прогони [`QUALITY_GATES.md`](QUALITY_GATES.md)

## Пример промпта (копипаст)

```
Реализуй Task Brief ниже. Batch B only. Не трогай файлы вне Scope.
Перед ответом: SELF_CHECK + run_composer_gates_headless.gd.

[Paste filled Task Brief]
```

## Связанные документы

- [DESIGN.md](../DESIGN.md)
- [PERFORMANCE.md](../PERFORMANCE.md)
- [MIGRATION.md](../MIGRATION.md)
- [tests/README.md](../tests/README.md)
