# PGDECS — шпаргалка

> **Роль:** рабочий минимум API на одной странице. Покрывает ~90% обращений к pgdecs в игровом коде.
> **Читать:** всегда, вместо `ecs/FRAMEWORK.md` (11k токенов) и `ecs/DESIGN.md` (13k).
> **Правила и запреты:** `AGENTS.md` рядом — читать вместе с этим файлом.
> **Идти дальше:** только если нужного API здесь нет. Тогда — `ecs/agent_handoff/AI_CODE_PATTERNS.md`, затем `ecs/FRAMEWORK.md`.
> **Статус:** normative (сигнатуры сверены с кодом аддона).

## Система с чанками — основной путь

```gdscript
extends ECSSystemChunkBase
class_name MySystem


func build_query() -> ECSQuery:
	return ECSQueryBuilder.new()\
		.with_component(MyWorld.Component.FOO)\
		.build(get_ecs_manager())


func process_chunk(chunk: ECSQueryChunk, delta: float) -> void:
	var foo_chunk: ECSComponentFloat32ArrayChunk = chunk.get_component_chunk(
		MyWorld.Component.FOO
	) as ECSComponentFloat32ArrayChunk
	if foo_chunk == null:
		return

	var slots: PackedInt32Array = chunk.get_dense_slots()
	var foo_buf: PackedFloat32Array = foo_chunk.get_values_buffer()

	for i: int in range(chunk.get_entity_count()):
		var slot: int = slots[i]
		foo_chunk.set_value_at_slot(slot, foo_buf[slot] + delta)
```

### ⚠ Буфер индексируется СЛОТОМ, а не `i`

Самая частая ошибка. `get_values_buffer()` отдаёт **плотный массив архетипа
целиком**, а не компактную выборку запроса. `i` — порядковый номер внутри чанка,
`slots[i]` — настоящая позиция значения в буфере.

```gdscript
foo_buf[i]       # ❌ чужие данные или выход за границу
foo_buf[slot]    # ✅
```

Писать так же: `set_value_at_slot(slot, value)`. Присваивание `foo_buf[slot] = x`
мимо API — у Packed-массивов буфер копия, изменение потеряется.

### Нужны id сущностей

```gdscript
	var entities: PackedInt64Array = chunk.get_dense_entities()
	var slots: PackedInt32Array = chunk.get_dense_slots()
	for i: int in range(chunk.get_entity_count()):
		var entity_id: int = entities[i]
		var slot: int = slots[i]
```

Оба массива идут в одном порядке: `i`-й элемент одного отвечает `i`-му другого.

`build_query()` и `process_chunk()` — `@abstract`. **Опечатка в сигнатуре = ошибка
парсера, а не тихий no-op**, но линтер её не покажет — судья только GUT.

## Система без чанков — `process_system`

Когда чанки не нужны: массовое уничтожение, разовое действие над результатом
запроса, работа с командным буфером.

```gdscript
extends ECSSystemBase
class_name MySweepSystem

var _query: ECSQuery


func _init(ecs_manager: ECSManager) -> void:
	super(ecs_manager)
	_query = ECSQueryBuilder.new()\
		.with_component(MyWorld.Tag.DOOMED)\
		.build(ecs_manager)


func process_system(_delta: float) -> void:
	var ids: PackedInt64Array = _query.get_entity_ids()
	if ids.is_empty():
		return

	var cb: ECSCommandBuffer = ECSCommandBuffer.new(get_ecs_manager())
	for id: int in ids:
		cb.destroy_entity(id)
```

**Запрос строится в `_init` и живёт полем** — не пересоздавать каждый кадр.

**Структурные изменения в две фазы:** сначала собрать id (`get_entity_ids()`),
потом менять. Удаление по живому запросу инвалидирует итерацию (swap-remove).

## Создание Node из PackedScene

`PackedScene` регистрируется компонентом `ECSComponent.Type.PACKED_SCENE`, ссылка
на созданную ноду — `NODE3D`. Проход выполняется на main thread, **не** в worker
pool; host задан заранее.

**Запрос обязан отсекать уже обработанные** — иначе сцена инстанцируется заново
на каждом прогоне, а прежняя нода течёт.

```gdscript
func build_query() -> ECSQuery:
	return ECSQueryBuilder.new()\
		.with_component(MyWorld.Component.PACKED_SCENE)\
		.with_component(MyWorld.Component.POSITION)\
		.without_component(MyWorld.Component.NODE3D)\
		.build(get_ecs_manager())


func process_chunk(chunk: ECSQueryChunk, _delta: float) -> void:
	var scene_chunk: ECSComponentPackedSceneArrayChunk = chunk.get_component_chunk(
		MyWorld.Component.PACKED_SCENE
	) as ECSComponentPackedSceneArrayChunk
	var pos_chunk: ECSComponentVector3iArrayChunk = chunk.get_component_chunk(
		MyWorld.Component.POSITION
	) as ECSComponentVector3iArrayChunk
	if scene_chunk == null or pos_chunk == null:
		return

	var entities: PackedInt64Array = chunk.get_dense_entities()
	var slots: PackedInt32Array = chunk.get_dense_slots()
	var scene_buf: Array[PackedScene] = scene_chunk.get_values_buffer()
	var pos_buf: Array[Vector3i] = pos_chunk.get_values_buffer()
	var cb: ECSCommandBuffer = get_command_buffer()

	for i: int in range(chunk.get_entity_count()):
		var slot: int = slots[i]
		var scene: PackedScene = scene_buf[slot]
		if scene == null:
			continue
		var node: Node3D = scene.instantiate() as Node3D
		if node == null:
			push_error("MySystem: корень сцены не Node3D")
			continue
		node.position = Vector3(pos_buf[slot])
		_host.add_child(node)
		cb.add_component(entities[i], MyWorld.Component.NODE3D, node)
```

Обрати внимание: `NODE3D` добавляется **через command buffer**, потому что это
структурное изменение — прямо в `process_chunk` его делать нельзя. Из-за этого
запрос `without_component(NODE3D)` сработает только со следующего прогона, и
двойного инстанцирования не будет.

## Создание ECS-сущностей из сцены

Для scene markers используй самостоятельный `ECSSceneEntityBlueprint`, а не
`ECSEntityBlueprint`: marker — `Node`, который хранит собственные scene-данные.
Координатор `ECSSceneWorldBlueprint` должен быть дочерним узлом `ECSWorld` и явно
назначен в `world.scene_world_blueprint`; автоматического поиска координатора нет.
`coordinator.scene_root` явно указывает корень рекурсивного поиска. Если поле
координатора в мире не задано, scene bootstrap выключен.

```gdscript
extends ECSSceneEntityBlueprint
class_name MySceneEntityBlueprint

@export var initial_position: Vector2 = Vector2.ZERO


func build_component_ids() -> PackedInt64Array:
	return PackedInt64Array([MyWorld.Component.POSITION])


func apply_defaults(buf: ECSCommandBuffer, entity_id: int) -> void:
	super.apply_defaults(buf, entity_id)
	buf.set_component(entity_id, MyWorld.Component.POSITION, initial_position)
```

`spawn_from_scene(buf)` не принимает `source_node`: marker сам отвечает за свои
данные и может типизированно применять собственные `@export`-поля. Не читай для
этого `get_parent()`. Для сложного спауна переопредели `spawn_from_scene(buf)` в
наследнике и реализуй нужную логику там; batch-spawn для обычного случая не нужен.

`ECSWorld` выполняет scene bootstrap после регистрации component schema и до
создания систем/первого тика. Все найденные сущности создаются одним command buffer.
Обход дерева не создаёт ECS parent-child связей, и новые marker-узлы после bootstrap
автоматически не обрабатываются. Не сохраняй временные entity ID из буфера как
значения компонентов.

## API, которым пользуются чаще всего

```gdscript
# чтение состояния вне системы (скрипты, тесты, фасады)
ecs.get_component_array(component_id: int) -> ECSComponentBaseArray
ecs.has_component(entity_id: int, component_id: int) -> bool
ecs.is_tag(component_id: int) -> bool

# внутри process_chunk
chunk.get_component_chunk(component_id: int) -> ECSComponentBaseArrayChunk
chunk.get_entity_count() -> int
chunk.get_dense_entities() -> PackedInt64Array   # нужны id сущностей
chunk.get_dense_slots() -> PackedInt32Array      # fast-path по значениям
<component_chunk>.get_values_buffer()            # прямой буфер значений

# запрос
ECSQueryBuilder.new().with_component(id).without_component(id).build(get_ecs_manager())

# из системы
get_ecs_manager() -> ECSManager
get_command_buffer() -> ECSCommandBuffer

# мир
world.run_system_group(group: StringName, delta: float) -> void
world.apply_profile(profile: ECSWorldProfile) -> void   # ровно один раз за lifecycle

# bootstrap и тесты — ВНЕ process_chunk, сразу настоящий id
ecs.create_entity_packed(component_ids: PackedInt64Array) -> int
ecs.set_component_value(entity_id: int, component_id: int, value: Variant) -> void
ecs.destroy_entity(entity_id: int) -> void
```

## Планирование групп

- Группа — ресурс `ECSSystemGroupConfig`: `group`, `enabled`, `process_hook`,
  `hz`, `execution_order`.
- Хуки: `PHYSICS_PROCESS`, `PROCESS`, `MANUAL`.
- `hz = 0` — каждый тик своего хука; `hz > 0` — через тикер с фиксированным шагом.
- `execution_order` сортирует группы **только внутри одного хука**.
- `ECSWorld._process` тикает `PROCESS`-группы, затем flush ручных буферов, затем
  сборку архетипов. `_physics_process` тикает `PHYSICS_PROCESS` и **ничего не
  флашит** — учитывай, если ставишь туда систему с command buffer.
- `MANUAL` запускается вручную: `world.run_system_group(&"name", delta)`.

## Что можно прямо в `process_chunk`, а что нет

| Нужно | Как |
| --- | --- |
| Изменить **значения** компонентов | `get_values_buffer()` / `set_value_at_slot` — прямо здесь |
| Создать, удалить сущность | **только** `get_command_buffer()` |
| Добавить, снять компонент | **только** `get_command_buffer()` |
| `use_worker_pool == true` | command buffer **запрещён** |

`ecs.create_entity*` / `destroy_*` / `add_component` / `remove_component` внутри `process_chunk` **звать нельзя**.

`buf.execute()` в production-системах не звать — это делает `ECSSystemRunner` после каждой системы.

## Шесть тихих ошибок

Ни одну не поймает линтер. Все проявляются как `null` или молчаливое бездействие.

1. **Поля, читаемые в `build_query()`, присвоены после `super(...)`** — `build_query()` вызывается внутри `super`, поля ещё пустые.
2. **`ECSQueryChunk` сохранён между кадрами** — `begin_chunk_run()` инвалидирует pooled views.
3. **`apply_profile()` вызван дважды** за жизнь мира.
4. **Temp id принят за настоящий** — `buf.create_entity()` возвращает отрицательный id до `execute()`; настоящий появляется после flush предыдущих систем того же `run_group`.
5. **Буфер проиндексирован `i` вместо `slots[i]`** — читаешь чужую сущность или
   выходишь за границу. Самая частая; см. раздел выше.
6. **`destroy_entity` без освобождения ссылок** — сначала release (`pool.release(node)` + снять reference-компонент), потом уничтожать.

## Устаревшее — не использовать

`InitStrategy`, `RegistryConfig`, `build_registry`, `visual_registry_strategy`, `ECSVisual*`, `ECSBridge*`, `absorb()`, slot-реестры (`ECSNodeRegistry`, `*_SLOT`, `INVALID_SLOT`).

Внешние объекты — reference-компоненты (`NODE`, `NODE2D`, `RESOURCE`, `REFCOUNTED`), ссылка лежит в SoA.

## Проверка после изменений в аддоне

```
godot --headless --path <project_root> --script res://addons/pgdecs/ecs/tests/run_composer_gates_headless.gd
```

Ожидание: `failed: 0`.
