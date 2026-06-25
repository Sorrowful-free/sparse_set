# Cursor AI rules (внутри аддона)

Правила PGDECS **живут в аддоне**, чтобы при копировании `addons/pgdecs/` в другой Godot-проект не настраивать корневой `.cursor/`.

## Что здесь

| Файл | Когда применяется |
|------|-------------------|
| [`../AGENTS.md`](../AGENTS.md) | Автоматически при работе с файлами в `addons/pgdecs/` |
| `rules/pgdecs-ecs-codegen.mdc` | GDScript в аддоне — итерация, command buffer, антипаттерны |
| `rules/pgdecs-ecs-handoff.mdc` | Документация и тесты — батчи, gates, scope |

Полная спецификация кода: [`../ecs/agent_handoff/AI_CODE_PATTERNS.md`](../ecs/agent_handoff/AI_CODE_PATTERNS.md).

## Переиспользование в новом проекте

1. Скопируйте папку `addons/pgdecs/` целиком (включая `.cursor/` и `AGENTS.md`).
2. Откройте **корень Godot-проекта** в Cursor (не только подпапку аддона).
3. Правила подхватятся из `addons/pgdecs/.cursor/rules/` (вложенные rules в monorepo поддерживаются).

### Если открываете только подпапку аддона

Cursor не поднимается к родительскому репозиторию. Варианты:

- Открывать корень игрового проекта (рекомендуется), или
- Симлинк в корень проекта (опционально):

```powershell
# из корня Godot-проекта (Windows, один раз)
New-Item -ItemType SymbolicLink -Path ".cursor\rules\pgdecs" -Target "addons\pgdecs\.cursor\rules"
```

## Проверка

В чате Agent при редактировании `addons/pgdecs/ecs/systems/*.gd` правило `pgdecs-ecs-codegen` должно быть доступно (Rules / контекст).
