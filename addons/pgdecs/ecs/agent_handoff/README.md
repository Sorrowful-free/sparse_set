# Agent Handoff (Composer)

Документация для делегирования задач модели **Composer** в Cursor с минимумом последующих правок.

## Быстрый старт

0. **Cursor (в аддоне):** [`../../AGENTS.md`](../../AGENTS.md) + [`../../.cursor/rules/`](../../.cursor/README.md)
1. **Перед генерацией gameplay/system кода** — [`AI_CODE_PATTERNS.md`](AI_CODE_PATTERNS.md)
2. Выбери **один** батч: [`BATCHES.md`](BATCHES.md)
3. Заполни [`TASK_BRIEF_TEMPLATE.md`](TASK_BRIEF_TEMPLATE.md) и вставь в промпт Composer
4. После работы — [`SELF_CHECK.md`](SELF_CHECK.md)
5. Прогони [`QUALITY_GATES.md`](QUALITY_GATES.md)

## Пример промпта (копипаст)

```
Реализуй Task Brief ниже. Batch B only. Не трогай файлы вне Scope.
Соблюдай addons/pgdecs/AGENTS.md и ecs/agent_handoff/AI_CODE_PATTERNS.md.
Перед ответом: SELF_CHECK + run_composer_gates_headless.gd.

[Paste filled Task Brief]
```

## Связанные документы

- [**AI_CODE_PATTERNS.md**](AI_CODE_PATTERNS.md) — обязательные паттерны для ИИ (итерация, command buffer)
- [DESIGN.md](../DESIGN.md)
- [PERFORMANCE.md](../PERFORMANCE.md)
- [MIGRATION.md](../MIGRATION.md)
- [tests/README.md](../tests/README.md)
