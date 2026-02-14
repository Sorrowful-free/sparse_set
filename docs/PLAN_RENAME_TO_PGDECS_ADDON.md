# План: переименование проекта в pgdecs и превращение в аддон Godot

## Цель

- Переименовать проект с **sparse_set** на **pgdecs** (P = **P**acked — упакованное представление данных).
- Оформить код как **аддон Godot 4**, чтобы его можно было подключать к любым проектам через `addons/pgdecs/`.

---

## 1. Структура аддона

В Godot аддон живёт в папке `addons/<имя_аддона>/`. Рекомендуемая структура:

```
project_root/
├── addons/
│   └── pgdecs/
│       ├── plugin.cfg          # манифест аддона (создать)
│       └── ecs/                 # текущая папка ecs переносится сюда
│           ├── ecs_manager.gd
│           ├── ecs_world.gd
│           ├── bit_mask/
│           ├── components/
│           ├── editor/
│           ├── entities/
│           ├── queries/
│           ├── systems/
│           ├── tests/
│           └── ...
├── project.godot
└── icon.svg                     # можно оставить в корне проекта
```

**Вариант без подпапки `ecs`:** можно положить содержимое `ecs/` прямо в `addons/pgdecs/` (тогда пути станут `res://addons/pgdecs/...`). Текущий план — оставить подпапку `ecs/`, чтобы минимизировать правки и сохранить группировку.

---

## 2. Чеклист задач

### Фаза A: Структура и манифест аддона

| # | Задача | Детали |
|---|--------|--------|
| A1 | Создать папку `addons/pgdecs/` | — |
| A2 | Переместить папку `ecs/` в `addons/pgdecs/ecs/` | Переместить целиком (все файлы и подпапки). |
| A3 | Создать `addons/pgdecs/plugin.cfg` | См. раздел 3 ниже. |
| A4 | Удалить старые `.uid` в корне (если остались ссылки на `ecs/`) | После переноса Godot пересоздаст `.uid` для файлов в `addons/pgdecs/ecs/`. |

### Фаза B: Пути в коде

| # | Задача | Детали |
|---|--------|--------|
| B1 | Обновить пути в `ecs_code_gen.gd` | `res://ecs/...` → `res://addons/pgdecs/ecs/...` (шаблоны и `components/generated`). |
| B2 | Проверить остальные скрипты на `res://ecs` или `res://addons` | На текущий момент только `ecs_code_gen.gd` содержит жёстко заданные пути. |

### Фаза C: Имя проекта и настройки

| # | Задача | Детали |
|---|--------|--------|
| C1 | Переименовать проект в `project.godot` | `config/name="sparse_set"` → `config/name="pgdecs"`. |
| C2 | При необходимости обновить `config/icon` | Если иконку перенесёте в аддон — путь станет `res://addons/pgdecs/icon.svg`. |
| C3 | Включить аддон в проекте | Project → Project Settings → Plugins → включить "PGDEcs" (или как назовёте в plugin.cfg). |

### Фаза D: Репозиторий и документация (по желанию)

| # | Задача | Детали |
|---|--------|--------|
| D1 | Переименовать репозиторий/папку проекта | Например `sparse_set` → `pgdecs` (локально и на GitHub/GitLab). |
| D2 | Обновить README, DESIGN.md, NAMING.md | Упоминания "sparse_set", путей `res://ecs` заменить на `pgdecs` и `res://addons/pgdecs/ecs`. |
| D3 | Обновить `ecs/tests/README.md` | Пути к тестам и способ запуска (если описан). |

### Фаза E: Проверка

| # | Задача | Детали |
|---|--------|--------|
| E1 | Открыть проект в Godot, включить плагин | Убедиться, что плагин появляется в списке и включается без ошибок. |
| E2 | Запустить юнит-тесты | Выполнить `run_unit_tests.gd` (EditorScript) и проверить, что все сьюты проходят. |
| E3 | Проверить кодогенератор | Запустить `ECSCodeGen` (EditorScript) и убедиться, что файлы генерируются в `addons/pgdecs/ecs/components/generated/`. |

---

## 3. Содержимое `plugin.cfg`

Создать файл **addons/pgdecs/plugin.cfg**:

```ini
[plugin]

name = "PGDEcs"
description = "Packed Entity-Component-System (ECS) для Godot 4 — упакованное представление данных на основе sparse set и архетипов."
author = "Ваше имя или ник"
version = "1.0.0"
script = ""
```

Поле `script` можно оставить пустым, если аддон не добавляет узлов в редактор и не требует автозагрузки. Если позже понадобится скрипт инициализации плагина (например, пункты меню для кодогенерации или тестов), укажите путь к нему, например: `script = "res://addons/pgdecs/plugin.gd"`.

---

## 4. Краткая последовательность действий

1. Создать `addons/pgdecs/`.
2. Переместить `ecs/` → `addons/pgdecs/ecs/`.
3. Создать `addons/pgdecs/plugin.cfg` (как в разделе 3).
4. В `addons/pgdecs/ecs/editor/ecs_code_gen.gd` заменить:
   - `res://ecs/editor/templates` → `res://addons/pgdecs/ecs/editor/templates`
   - `res://ecs/components/generated` → `res://addons/pgdecs/ecs/components/generated`
5. В `project.godot`: `config/name="pgdecs"`.
6. Открыть проект в Godot → Project Settings → Plugins → включить аддон.
7. Прогнать тесты и кодогенератор.
8. При необходимости обновить README и прочую документацию, переименовать репозиторий.

После этого проект будет называться **pgdecs** (P = Packed) и распространяться как аддон в папке `addons/pgdecs/`.
