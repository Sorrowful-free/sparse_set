# Обособление ECS-классов: префикс и план

## Зачем

- В списке классов редактора и автодополнении все ECS-типы визуально сгруппированы (например, по префиксу `ECS`).
- Явно видно, что класс принадлежит этому модулю, меньше конфликтов имён с игровым кодом.
- Удобнее документировать и искать: «всё, что начинается с ECS».

---

## Текущее состояние (после переименования)

Все классы ECS имеют префикс **ECS**:

| Класс | Описание |
|-------|----------|
| ECSManager | Менеджер мира |
| ECSCommandBuffer | Отложенные команды |
| ECSArchetype | Архетип сущностей |
| ECSQuery, ECSQueryBuilder | Запросы |
| ECSSystemBase, ECSSystemRunner | Системы |
| ECSComponentRegistryStrategy | Схема ECS: `get_tags()`, `get_components()` (одна на profile) |
| ECSSystemStrategy, ECSComponentRegistryStrategy, ECSWorldProfile | Профиль мира и стратегии |
| `INTENT_*` | Intent-теги (marker): bind / release / destroy |
| `*_SLOT` | Slot-компонент (Int32): индекс в Resource-реестре, `-1` = нет |
| `*Registry` (игра) | Resource side-table вне ECS, напр. `ECSNodeRegistry` |
| `*EcsDependencies` | Resource-контейнер реестров для strategies (см. ниже) |
| ECSEntityIdsPool, ECSEntityIdsUtils | Пул и утилиты ID |
| ECSBitMask, ECSBitMaskOperations | Битовые маски |
| ECSComponent | enum `Type` — типы хранилищ компонентов (packed / value / reference) |
| ECSComponentFactory | Фабрика компонентов (по `ECSComponent.Type`) |
| ECSComponentBaseArray, ECSComponentBaseArrayChunk | Базовые классы компонентов |
| ECSComponentByteArray, ECSComponentVector2Array, … | Сгенерированные компоненты |

Тесты: EntityIdsUtilsTest, ArchetypeTest, QueryTest и т.д. (имена сьютов без префикса ECS).

**Имена файлов** приведены в соответствие с классами (префикс `ecs_` в имени файла):
- `archetype.gd` → `ecs_archetype.gd`, `query.gd` → `ecs_query.gd`, …
- `component_byte_array.gd` → `ecs_component_byte_array.gd`, …
- Кодогенератор создаёт файлы `ecs_component_<type>_array.gd` и `ecs_component_<type>_chunk_array.gd`.

---

## Зависимости и реестры в игре

Один паттерн — разные имена по слою:

| Слой | class_name | Пример |
|------|------------|--------|
| Эталон аддона | `ExampleEcsDependencies` | `examples/dependencies/` |
| Игра (общий bag) | `GameEcsDependencies` | `scripts/ecs/dependencies/` |
| Игра (модуль) | `R_<Module>Dependencies` | `R_LodDependencies`, `R_NetworkDependencies` |

`ExampleEcsDependencies` и `GameEcsDependencies` — те же идеи: `extends Resource`, `@export` на реестры/settings, инжект в `ECSSystemStrategy.dependencies`. В доменных модулях принят префикс **`R_`** (Godot Resource) и **один bag на модуль**, не один глобальный на весь ECS.

Реестры (`*Registry`) — side-table; API может быть slot-based (`acquire` / `release`) или handle-based (`get_or_register` / `unregister` по wire-id) — см. [OBJECT_COMPONENTS.md](OBJECT_COMPONENTS.md).

---

## Варианты

### Вариант A. Единый префикс `ECS` для всего публичного API

Переименовать только то, что вызывается из игрового кода и редактора:

| Было            | Стало           |
|-----------------|------------------|
| Archetype       | ECSArchetype     |
| Query           | ECSQuery         |
| QueryBuilder    | ECSQueryBuilder  |
| SystemBase      | ECSSystemBase    |
| SystemRunner    | ECSSystemRunner  |
| EntityIdsPool   | ECSEntityIdsPool |
| EntityIdsUtils  | ECSEntityIdsUtils (или оставить — утилиты) |
| ComponentFactory| ECSComponentFactory |
| BitMask         | ECSBitMask (опционально, если только для ECS) |

**Не трогаем (внутренние / сгенерированные):**  
ComponentBaseArray, ComponentBaseArrayChunk, ComponentVector2Array и т.д. — длинные имена и много мест (фабрика, шаблоны, примеры). Либо оставить, либо вынести в отдельную фазу с префиксом `ECSComponent*`.

**Плюсы:** минимум правок, явный «фасад» ECS.  
**Минусы:** смесь стилей (ECSArchetype vs ComponentVector2Array).

---

### Вариант B. Префикс `ECS` везде, включая компоненты

Плюс к варианту A:

- ComponentBaseArray → ECSComponentBaseArray  
- ComponentBaseArrayChunk → ECSComponentBaseArrayChunk  
- ComponentByteArray → ECSComponentByteArray  
- ComponentVector2Array → ECSComponentVector2Array  
- … все сгенерированные типы.

**Плюсы:** единообразие, в списке классов все ECS-типы под одним префиксом.  
**Минусы:** много изменений: фабрика, все сцены/скрипты с типами компонентов, шаблоны и кодогенератор (ecs_code_gen.gd), пример (GameComponents, bootstrap).

---

### Вариант C. Только документировать, не менять имена

В DESIGN.md или README описать:

- Публичный API: ECSManager, ECSCommandBuffer, Query, QueryBuilder, SystemBase, SystemRunner.
- Внутренние типы: Archetype, EntityIdsPool, ComponentFactory, компоненты Component*.
- Все классы под папкой `ecs/` считаются частью ECS.

**Плюсы:** без рефакторинга.  
**Минусы:** в редакторе классы не сгруппированы по префиксу.

---

### Вариант D. Префикс только для «точек входа»

Оставить как есть всё, что уже с префиксом (ECSManager, ECSCommandBuffer). Добавить префикс только самому видимому API запросов и систем:

- Query → ECSQuery  
- QueryBuilder → ECSQueryBuilder  
- SystemBase → ECSSystemBase  
- SystemRunner → ECSSystemRunner  

Archetype, EntityIdsPool, BitMask, Component* не менять.

**Плюсы:** мало правок, при этом запросы и системы в коде игры будут однозначно ECS-скими.  
**Минусы:** частичное единообразие.

---

## Рекомендация

- **Сделать сейчас (низкий объём):** **Вариант D** — переименовать Query, QueryBuilder, SystemBase, SystemRunner в ECSQuery, ECSQueryBuilder, ECSSystemBase, ECSSystemRunner. Обновить пример, тесты и DESIGN.md.
- **Позже при желании:** Вариант A (Archetype, EntityIdsPool, ComponentFactory и т.д.) или B (включая компоненты) — отдельной задачей с обновлением кодогенератора и шаблонов.

---

## Что править при смене имён (чеклист)

Для любого переименования класса:

1. **Файл класса:** строка `class_name X` → новое имя.
2. **Все ссылки на тип:** объявления переменных, аннотации типов, `as X`, `.new()`.
3. **Файлы в проекте:** ecs_manager.gd, ecs_command_buffer.gd, query.gd, query_builder.gd, system_base.gd, system_runner.gd, component_factory.gd, entity_ids_pool.gd; пример (game_components.gd, bootstrap.gd); тесты (unit/*, performance/*).
4. **Кодогенерация:** ecs_code_gen.gd — если там есть имена классов; шаблоны `{component_type_array}.gdt`, `{component_type_array_chunk}.gdt` — плейсхолдеры типов.
5. **Документация:** DESIGN.md, PERFORMANCE.md, README, этот NAMING.md — заменить старые имена на новые.

Если решите конкретный вариант (A, B, C или D), можно расписать пошаговый план правок по файлам.
