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
		.with_component(MyWorld.Component.BAR)\
		.build(get_ecs_manager())

func process_chunk(chunk: ECSQueryChunk, delta: float) -> void:
	var foo := chunk.get_component_chunk(MyWorld.Component.FOO) as ECSComponentFooArrayChunk
	if foo == null:
		return
	var values := foo.get_values_buffer()
	for i in chunk.get_entity_count():
		values[i] = ...   # мутация значений — можно прямо здесь
```

`build_query()` и `process_chunk()` — `@abstract`. **Опечатка в сигнатуре = ошибка парсера, а не тихий no-op**, но линтер редактора её не покажет — судья только GUT.

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

## Что можно прямо в `process_chunk`, а что нет

| Нужно | Как |
| --- | --- |
| Изменить **значения** компонентов | `get_values_buffer()` / `set_value_at_slot` — прямо здесь |
| Создать, удалить сущность | **только** `get_command_buffer()` |
| Добавить, снять компонент | **только** `get_command_buffer()` |
| `use_worker_pool == true` | command buffer **запрещён** |

`ecs.create_entity*` / `destroy_*` / `add_component` / `remove_component` внутри `process_chunk` **звать нельзя**.

`buf.execute()` в production-системах не звать — это делает `ECSSystemRunner` после каждой системы.

## Пять тихих ошибок

Ни одну не поймает линтер. Все проявляются как `null` или молчаливое бездействие.

1. **Поля, читаемые в `build_query()`, присвоены после `super(...)`** — `build_query()` вызывается внутри `super`, поля ещё пустые.
2. **`ECSQueryChunk` сохранён между кадрами** — `begin_chunk_run()` инвалидирует pooled views.
3. **`apply_profile()` вызван дважды** за жизнь мира.
4. **Temp id принят за настоящий** — `buf.create_entity()` возвращает отрицательный id до `execute()`; настоящий появляется после flush предыдущих систем того же `run_group`.
5. **`destroy_entity` без освобождения ссылок** — сначала release (`pool.release(node)` + снять reference-компонент), потом уничтожать.

## Устаревшее — не использовать

`InitStrategy`, `RegistryConfig`, `build_registry`, `visual_registry_strategy`, `ECSVisual*`, `ECSBridge*`, `absorb()`, slot-реестры (`ECSNodeRegistry`, `*_SLOT`, `INVALID_SLOT`).

Внешние объекты — reference-компоненты (`NODE`, `NODE2D`, `RESOURCE`, `REFCOUNTED`), ссылка лежит в SoA.

## Проверка после изменений в аддоне

```
godot --headless --path <project_root> --script res://addons/pgdecs/ecs/tests/run_composer_gates_headless.gd
```

Ожидание: `failed: 0`.
