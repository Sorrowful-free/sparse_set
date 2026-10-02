# План: создание ECSWorld из сцены

> Реализация завершена: scene-blueprint — отдельные Node-классы; world-координатор является дочерним узлом `ECSWorld` и явно назначается в export-поле. Выбранные правила поиска и source node записаны ниже.

## Рекомендуемые имена

- `ECSSceneEntityBlueprint` — Node-маркер, описывающий ECS-сущность, создаваемую из узла сцены.
- `ECSSceneWorldBlueprint` — Node-координатор, собирающий сущности сцены в ECSWorld.

Эта пара явно показывает, что типы относятся к сценовой интеграции. Общий `ECSEntityBlueprint` остаётся отдельным типом.

## Разделение ответственности

- `ECSSceneEntityBlueprint` — самостоятельный `Node`. Он **не наследуется** от `ECSEntityBlueprint` и **не хранит ссылку** на него.
- В `ECSSceneEntityBlueprint` определяется собственный контракт создания сущности: component ID, дефолтные значения, spawn и применение значений источника-сцены.
- `ECSSceneWorldBlueprint` находит/обходит scene-маркеры, выбирает корень поиска и вызывает их spawn в общем bootstrap command buffer.
- Маркеры находятся в конкретной сцене; не хранить сериализуемый `Array[Node]` в общем `Resource`.

Независимые классы дублируют небольшой общий шаблон создания и дефолтов намеренно: generic blueprint не приобретает Node-зависимость, а сценовый класс не зависит от API generic blueprint. При изменении контракта эти два API нужно поддерживать согласованно и покрывать отдельными тестами.

## Предлагаемый API `ECSSceneEntityBlueprint`

Scene-класс зеркально определяет нужные части контракта generic blueprint, но является самостоятельным `Node`:

```gdscript
@abstract
class_name ECSSceneEntityBlueprint extends Node

@abstract func build_component_ids() -> PackedInt64Array

func build_default_values() -> Dictionary:
    return {}

func spawn_from_scene(buf: ECSCommandBuffer, source_node: Node) -> int:
    var entity_id := buf.create_entity_packed(build_component_ids())
    apply_defaults(buf, entity_id, source_node)
    return entity_id

func apply_defaults(
    buf: ECSCommandBuffer,
    entity_id: int,
    source_node: Node
) -> void:
    # Применить build_default_values(), затем/либо через override — данные source_node.
    pass
```

Смысл API:

- `build_component_ids()` задаёт состав ECS-сущности.
- `build_default_values()` — статические общие значения `{ component_id: value }`.
- `spawn_from_scene()` создаёт одну сущность из одного источника сцены и вызывает инициализацию.
- `apply_defaults()` применяет статические значения и предоставляет наследнику доступ к `source_node` для записи scene-derived компонентов через `buf.set_component(...)`. Переопределение может вызывать `super.apply_defaults(...)`, чтобы сохранить общие значения.

Здесь нет отдельного универсального `meta_data` со значениями сцены: конкретный класс может типизированно читать поля из `source_node`. Реализованный контракт использует `spawn_from_scene(buf, source_node)` и `apply_defaults(buf, entity_id, source_node)`; наследник вызывает `super.apply_defaults(...)` для сохранения статических дефолтов.

Для Node-маркера достаточно одиночного spawn: один scene marker обычно описывает одну сущность. Несколько маркеров можно обработать одним общим command buffer. Batch API в scene entity blueprint добавлять только при подтверждённой потребности.

## Размещение маркеров и источник данных

Реализованное правило: `ECSSceneWorldBlueprint.scene_root` — явная экспортируемая ссылка на корень поиска. Координатор рекурсивно обходит его и находит все узлы `ECSSceneEntityBlueprint` в порядке обхода дочерних узлов. Каждый marker должен быть дочерним узлом source Node; непосредственный родитель marker-а передаётся в `spawn_from_scene`/`apply_defaults`. Marker без родителя пропускается с предупреждением.

Конкретный вид сущности задаётся скриптом-наследником `ECSSceneEntityBlueprint`, который реализует `build_component_ids()` и при необходимости `build_default_values()`/`apply_defaults()`. Универсального словаря scene-данных нет.

## Размещение world coordinator и профиль

`ECSSceneWorldBlueprint` — дочерний `Node` внутри `ECSWorld`, но координатор не ищется автоматически: в `ECSWorld` есть экспортируемое поле типа `ECSSceneWorldBlueprint`, и сцена явно назначает в нём дочерний узел. Так одновременно фиксируются владение в дереве и явная настройка в Inspector.

Отсутствующее назначение (`null`) означает, что построение ECS из сцены выключено. Ссылка на Node не помещается в `ECSWorldProfile`: профиль остаётся переиспользуемым `Resource` для schema/system-настроек, а ссылка на сценовый координатор принадлежит экземпляру `ECSWorld` в конкретной сцене.

## Порядок инициализации

1. Инициализировать runtime ECS.
2. Зарегистрировать component schema через `component_registry_strategy`.
3. Если scene world coordinator присутствует, найти scene entity markers, создать сущности и выполнить bootstrap command buffer.
4. Установить расписание систем и создать системы.
5. Начать обычные тики.

Координатор не должен запускать bootstrap самостоятельно в `_ready()`, если не гарантирована готовность `ECSWorld`. Предпочтительно, чтобы `ECSWorld` явно вызвал его после регистрации schema. Узлы сцены существуют к `_ready()`, но `_ready()` некоторых соседних узлов может ещё не завершиться.

## Иерархия сцены и связи ECS

Первая версия только обходит дерево и создаёт ECS-сущности для marker-узлов; parent-child связи не переносятся. Подходящих relation-компонентов и API в ECS-ядре не обнаружено. Для будущего сохранения ECS-иерархии нужны отдельное соответствие `Node → реальный ECS entity ID` и отдельный протокол. `ECSCommandBuffer` разрешает временные ID только внутри одного `execute()` и очищает mapping после него; временный ID нельзя сохранять как значение компонента.

## Реализованный lifecycle и тесты

`ECSWorld.apply_profile()` выполняет этапы строго в таком порядке: регистрация schema через `ECSWorldProfile`, scene bootstrap (если явно назначен координатор), установка расписания и создание систем. Координатор не запускается из `_ready()` самостоятельно. Один marker создаёт одну сущность; все сущности в одном проходе записываются и выполняются общим bootstrap command buffer до первого тика. Повторный `apply_profile()` игнорируется существующим lifecycle guard, поэтому сущности не дублируются.

GUT-покрытие находится в `addons/pgdecs/ecs/tests/unit/ecs_scene_world_blueprint_test.gd`: отсутствующее назначение, marker+дефолты+scene-derived значение, bootstrap до фабрики систем/первого тика и отсутствие дублей при повторном применении профиля.

## Закрытые решения

- Корень поиска задаётся явно через `ECSSceneWorldBlueprint.scene_root`; `current_scene` не используется.
- Marker — дочерний узел source Node; source — непосредственный родитель.
- Тип/IDs/scene-значения задаются скриптом-наследником и типизированным чтением source Node.
- ECS parent-child связи не входят в первую версию.
