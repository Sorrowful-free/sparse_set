class_name ECSQuery extends RefCounted

var _components_bitmask: ECSBitMask
var _without_components_bitmask: ECSBitMask

var _component_ids: PackedInt64Array
var _without_component_ids: PackedInt64Array

var _ecs_manager: ECSManager

func _init(ecs_manager: ECSManager, component_ids: PackedInt64Array, without_component_ids: PackedInt64Array) -> void:
	_ecs_manager = ecs_manager
	_component_ids = component_ids
	_without_component_ids = without_component_ids
	var max_component_id: int = 0
	for component_id in component_ids:
		if component_id > max_component_id:
			max_component_id = component_id
	for component_id in without_component_ids:
		if component_id > max_component_id:
			max_component_id = component_id
	var mask_capacity: int = max(1, max_component_id + 1)
	_components_bitmask = ECSBitMask.new(mask_capacity)
	_without_components_bitmask = ECSBitMask.new(mask_capacity)
	for component_id in component_ids:
		_components_bitmask.bit_set(component_id, true)
	for component_id in without_component_ids:
		_without_components_bitmask.bit_set(component_id, true)

func match(entity_id: int) -> bool:
	# Проверяем наличие обязательных компонентов
	for component_id in _component_ids:
		if !_ecs_manager.has_component(entity_id, component_id):
			return false
	
	# Проверяем отсутствие запрещенных компонентов
	for component_id in _without_component_ids:
		if _ecs_manager.has_component(entity_id, component_id):
			return false
	
	return true

## Возвращает все entity_id, подходящие под запрос, без вызова match() по каждой сущности.
## Обходит только архетипы, подходящие под with/without, затем чанки сущностей.
func get_entity_ids() -> PackedInt64Array:
	var result: PackedInt64Array = PackedInt64Array()
	for chunk in get_chunks():
		var ids: PackedInt64Array = chunk.get_entity_ids()
		for i in range(ids.size()):
			if ids[i] >= 0:
				result.append(ids[i])
	return result

## Возвращает чанки результата запроса. Итерация по чанкам позволяет:
## — итерироваться строго по чанкам (кэш-френдли);
## — раздавать диапазоны чанков разным параллельным воркерам.
## Каждый элемент — ECSQueryChunk (entity_ids чанка + доступ к чанкам компонентов для SoA).
func get_chunks() -> Array[ECSQueryChunk]:
	var result: Array[ECSQueryChunk] = []
	var archetypes: Array = _ecs_manager.get_archetypes()
	for archetype in archetypes:
		var arch: ECSArchetype = archetype as ECSArchetype
		if arch == null:
			continue
		var arch_mask: ECSBitMask = ECSBitMask.new(arch._bits.size() * ECSBitMask.MAX_INT_CAPACITY)
		arch_mask.bit_copy_from(arch._bits)
		if !arch_mask.bit_match(_components_bitmask):
			continue
		var has_forbidden: bool = false
		for without_id in _without_component_ids:
			if arch_mask.bit_test(without_id):
				has_forbidden = true
				break
		if has_forbidden:
			continue
		for entity_ids_chunk in arch.get_chunks():
			if entity_ids_chunk.is_empty():
				continue
			result.append(ECSQueryChunk.new(entity_ids_chunk, _ecs_manager))
	return result
