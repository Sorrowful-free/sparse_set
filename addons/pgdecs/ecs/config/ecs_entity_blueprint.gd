@abstract
class_name ECSEntityBlueprint extends Resource

## Абстрактный blueprint сущности: набор component_id (int) + инициализация значений.
## Игра наследует Resource, в [method build_component_ids] возвращает id из своего enum
## (тот же int, что в [ECSComponentRegistryStrategy]).
##
## Spawn и параметры — **только** через [ECSCommandBuffer]:
## create + [method ECSCommandBuffer.set_component_value] в одном буфере, затем [method ECSCommandBuffer.execute].
## В системе execute делает [ECSSystemRunner]; при bootstrap — свой буфер + execute.

var _cached_component_ids: PackedInt64Array = PackedInt64Array()
var _cached_archetype: PackedInt64Array = PackedInt64Array()
var _cached_node_bindings: Array[ECSBlueprintNodeBinding] = []

## Нормализованный набор component id (без тегов-only если не нужны в архетипе).
@abstract func build_component_ids() -> PackedInt64Array

## Статические дефолты { component_id: value } для [method apply_defaults].
## Переопредели для простых констант; для сложной логики — [method apply_defaults].
func build_default_values() -> Dictionary:
	return {}

## Привязки нод: какой reference-компонент получает инстанс [PackedScene].
## Переопредели, чтобы blueprint описывал и создание нод (см. [method spawn_one_bound]).
## Корень сцены обязан совпадать с типом хранилища компонента (`NODE3D` → `Node3D`).
func build_node_bindings() -> Array[ECSBlueprintNodeBinding]:
	return []

func get_node_bindings() -> Array[ECSBlueprintNodeBinding]:
	if _cached_node_bindings.is_empty():
		_cached_node_bindings = build_node_bindings()
	return _cached_node_bindings

## component_id из [method build_node_bindings] добавляются в архетип автоматически:
## иначе binding писал бы значение в компонент вне членства (рассинхрон архетипа и чанка).
## Binding без сцены ([method ECSBlueprintNodeBinding.is_active]) — no-op.
func get_component_ids() -> PackedInt64Array:
	if _cached_component_ids.is_empty():
		var ids: PackedInt64Array = build_component_ids()
		for binding: ECSBlueprintNodeBinding in get_node_bindings():
			if binding == null or not binding.is_active() or ids.has(binding.component_id):
				continue
			ids.append(binding.component_id)
		_cached_component_ids = ids
	return _cached_component_ids

func get_archetype(ecs: ECSManager) -> PackedInt64Array:
	if _cached_archetype.is_empty():
		_cached_archetype = ecs.prepare_archetype(get_component_ids())
	return _cached_archetype

func invalidate_cache() -> void:
	_cached_component_ids = PackedInt64Array()
	_cached_archetype = PackedInt64Array()
	_cached_node_bindings = []

## Batch: create_entities_packed + [method apply_instance] на каждый temp id в том же буфере.
func spawn_batch(buf: ECSCommandBuffer, count: int) -> PackedInt64Array:
	if count <= 0:
		return PackedInt64Array()
	get_archetype(buf.get_ecs_manager())
	var entity_ids: PackedInt64Array = buf.create_entities_packed(count, get_component_ids())
	apply_instances(buf, entity_ids)
	return entity_ids

## Одна сущность; temp id до execute.
func spawn_one(buf: ECSCommandBuffer) -> int:
	var entity_ids: PackedInt64Array = spawn_batch(buf, 1)
	if entity_ids.is_empty():
		return 0
	return entity_ids[0]

## Алиас [method spawn_batch] при count == 1.
func spawn(buf: ECSCommandBuffer, count: int = 1) -> PackedInt64Array:
	return spawn_batch(buf, count)

## Spawn + [method apply_node_bindings] в **одном** буфере: сущность создаётся уже с нодами
## (окна «сущность без ноды» нет — create и set применяются на `execute()` подряд).
## [param host] — узел, к которому добавляются созданные ноды (может быть `null`).
## **Main thread**, вне `process_chunk`: создание нод — операция над деревом сцены.
func spawn_batch_bound(buf: ECSCommandBuffer, count: int, host: Node = null) -> PackedInt64Array:
	var entity_ids: PackedInt64Array = spawn_batch(buf, count)
	apply_node_bindings(buf, entity_ids, host)
	return entity_ids

func spawn_one_bound(buf: ECSCommandBuffer, host: Node = null) -> int:
	var entity_ids: PackedInt64Array = spawn_batch_bound(buf, 1, host)
	if entity_ids.is_empty():
		return 0
	return entity_ids[0]

## Создаёт по инстансу **на сущность** для каждой [method build_node_bindings] и кладёт его
## в компонент через буфер ([method ECSCommandBuffer.set_component_value]).
## Инстансы не шарятся между сущностями — в отличие от ссылок в [method build_default_values].
func apply_node_bindings(
	buf: ECSCommandBuffer, entity_ids: PackedInt64Array, host: Node = null
) -> void:
	var bindings: Array[ECSBlueprintNodeBinding] = get_node_bindings()
	if bindings.is_empty():
		return
	if not Thread.is_main_thread():
		push_error("ECSEntityBlueprint.apply_node_bindings: requires main thread")
		return
	for i in range(entity_ids.size()):
		var entity_id: int = entity_ids[i]
		if entity_id == 0:
			continue
		for binding: ECSBlueprintNodeBinding in bindings:
			if binding == null or not binding.is_active():
				continue
			var node: Node = binding.instantiate(host)
			if node == null:
				continue
			buf.set_component_value(entity_id, binding.component_id, node)

func apply_instances(buf: ECSCommandBuffer, entity_ids: PackedInt64Array) -> void:
	for i in range(entity_ids.size()):
		var entity_id: int = entity_ids[i]
		if entity_id != 0:
			apply_instance(buf, entity_id, i)

## Общие дефолты: [method build_default_values] → [method ECSCommandBuffer.set_component_value].
## Переопредели для доп. логики; вызови [code]super.apply_defaults[/code] чтобы сохранить dict.
func apply_defaults(buf: ECSCommandBuffer, entity_id: int) -> void:
	var defaults: Dictionary = build_default_values()
	for component_id: Variant in defaults:
		buf.set_component_value(entity_id, int(component_id), defaults[component_id])

## Параметры одного инстанса (index в batch). По умолчанию — [method apply_defaults].
func apply_instance(buf: ECSCommandBuffer, entity_id: int, _index: int) -> void:
	apply_defaults(buf, entity_id)
