extends RefCounted
class_name ECSManager

## Контракт с компонентами: add_entity / remove_entity / has_entity. Размер чанка — ECSEntityIdsUtils.CHUNK_SIZE (см. ecs/DESIGN.md).
var _entity_ids_pool: ECSEntityIdsPool = ECSEntityIdsPool.new()

var _components: Dictionary[int, ECSComponentBaseArray] = {}
var _archetypes: Dictionary[int, ECSArchetype] = {}
var _entities_to_archetypes: PackedInt64Array = PackedInt64Array()

## Кэш для create_entity/create_entities: ключ набора component_ids -> ECSBitMask и PackedInt64Array (Фаза B).
var _archetype_cache: Dictionary = {}

## Переиспользуемые буферы для add_component/remove_component (Фаза D).
var _work_component_ids: PackedInt64Array = PackedInt64Array()
var _work_bitmask: ECSBitMask = ECSBitMask.new(1)

func _init() -> void:
	pass

## Заполняет _work_bitmask по _work_component_ids и возвращает bit_hash().
func _work_bitmask_hash() -> int:
	var max_id: int = 0
	for c_id in _work_component_ids:
		if c_id > max_id:
			max_id = c_id
	_work_bitmask.bit_resize(max_id + 1)
	_work_bitmask.bit_clear_all()
	for c_id in _work_component_ids:
		_work_bitmask.bit_set(c_id, true)
	return _work_bitmask.bit_hash()

## Возвращает строковый ключ для набора component_ids (одинаковый для одного и того же набора).
func _get_component_set_key(component_ids: Array) -> String:
	var sorted_ids: Array = component_ids.duplicate()
	sorted_ids.sort()
	var parts: PackedStringArray = PackedStringArray()
	for cid in sorted_ids:
		parts.append(str(cid))
	return ",".join(parts)

## Возвращает архетип и packed_component_ids для набора component_ids (из кэша или создаёт и кэширует).
func _get_or_create_archetype_info(component_ids: Array) -> Dictionary:
	var key: String = _get_component_set_key(component_ids)
	if _archetype_cache.has(key):
		return _archetype_cache[key]
	var packed: PackedInt64Array = PackedInt64Array(component_ids)
	var max_component_id: int = 0
	for cid in component_ids:
		if cid > max_component_id:
			max_component_id = cid
	var bits: ECSBitMask = ECSBitMask.new(max_component_id + 1)
	for cid in component_ids:
		bits.bit_set(cid, true)
	var info: Dictionary = { "bitmask": bits, "packed": packed }
	_archetype_cache[key] = info
	return info

func register_component(component_id: int, component_type: Variant.Type) -> void:
	if _components.has(component_id):
		return
	var component: ECSComponentBaseArray = ECSComponentFactory.create_component(component_type)
	if component == null:
		return
	_components[component_id] = component

func get_component_array(component_id: int) -> ECSComponentBaseArray:
	return _components.get(component_id, null)

func create_entity(...component_ids: Array) -> int:
	var entity_id: int = _entity_ids_pool.get_next_entity_id()
	var info: Dictionary = _get_or_create_archetype_info(component_ids)
	var bits: ECSBitMask = info.bitmask
	var packed_component_ids: PackedInt64Array = info.packed
	var archetype_hash: int = bits.bit_hash()

	if !_archetypes.has(archetype_hash):
		_archetypes[archetype_hash] = ECSArchetype.new(bits._bits, packed_component_ids)
	var archetype: ECSArchetype = _archetypes[archetype_hash]
	archetype.add_entity(entity_id)

	if entity_id >= _entities_to_archetypes.size():
		_entities_to_archetypes.resize(entity_id + 1)
	_entities_to_archetypes[entity_id] = archetype_hash

	for component_id in packed_component_ids:
		var component: ECSComponentBaseArray = _components.get(component_id, null)
		if component != null:
			component.add_entity(entity_id)

	return entity_id

func create_entities(count: int, ...component_ids: Array) -> PackedInt64Array:
	if count <= 0:
		return PackedInt64Array()

	var entity_ids: PackedInt64Array = PackedInt64Array()
	entity_ids.resize(count)

	var info: Dictionary = _get_or_create_archetype_info(component_ids)
	var bits: ECSBitMask = info.bitmask
	var packed_component_ids: PackedInt64Array = info.packed
	var archetype_hash: int = bits.bit_hash()

	if !_archetypes.has(archetype_hash):
		_archetypes[archetype_hash] = ECSArchetype.new(bits._bits, packed_component_ids)
	var archetype: ECSArchetype = _archetypes[archetype_hash]

	for i in range(count):
		var entity_id: int = _entity_ids_pool.get_next_entity_id()
		entity_ids[i] = entity_id
		archetype.add_entity(entity_id)
		if entity_id >= _entities_to_archetypes.size():
			_entities_to_archetypes.resize(entity_id + 1)
		_entities_to_archetypes[entity_id] = archetype_hash
		for component_id in packed_component_ids:
			var component: ECSComponentBaseArray = _components.get(component_id, null)
			if component != null:
				component.add_entity(entity_id)

	return entity_ids

func destroy_entity(entity_id: int) -> void:
	if entity_id < 0 || entity_id >= _entities_to_archetypes.size():
		return
	
	var archetype_hash: int = _entities_to_archetypes[entity_id]
	var archetype: ECSArchetype = null
	if _archetypes.has(archetype_hash):
		archetype = _archetypes[archetype_hash]
		archetype.remove_entity(entity_id)
	
	# Удаляем сущность только из компонентов её архетипа (если архетип не найден — из всех, на случай некорректного состояния)
	var component_ids_to_clear: PackedInt64Array
	if archetype != null:
		component_ids_to_clear = archetype._component_ids
	else:
		component_ids_to_clear = PackedInt64Array(_components.keys())
	for component_id in component_ids_to_clear:
		var component: ECSComponentBaseArray = _components.get(component_id, null)
		if component != null && component.has_entity(entity_id):
			component.remove_entity(entity_id)
	
	_entity_ids_pool.free_entity_id(entity_id)
	
	if entity_id < _entities_to_archetypes.size():
		_entities_to_archetypes[entity_id] = -1

func destroy_entities(entity_ids: PackedInt64Array) -> void:
	if entity_ids.is_empty():
		return
	
	# Группируем по архетипу для батч-удаления
	var by_archetype: Dictionary = {}
	for entity_id in entity_ids:
		if entity_id < 0 || entity_id >= _entities_to_archetypes.size():
			continue
		var archetype_hash: int = _entities_to_archetypes[entity_id]
		if archetype_hash < 0:
			continue
		if !by_archetype.has(archetype_hash):
			by_archetype[archetype_hash] = PackedInt64Array()
		by_archetype[archetype_hash].append(entity_id)
	
	for archetype_hash in by_archetype.keys():
		var batch: PackedInt64Array = by_archetype[archetype_hash]
		var archetype: ECSArchetype = _archetypes.get(archetype_hash, null)
		if archetype == null:
			for eid in batch:
				for comp_id in _components.keys():
					var comp: ECSComponentBaseArray = _components[comp_id]
					if comp != null && comp.has_entity(eid):
						comp.remove_entity(eid)
				_entity_ids_pool.free_entity_id(eid)
				if eid < _entities_to_archetypes.size():
					_entities_to_archetypes[eid] = -1
			continue
		for eid in batch:
			archetype.remove_entity(eid)
		for component_id in archetype._component_ids:
			var component: ECSComponentBaseArray = _components.get(component_id, null)
			if component != null:
				for eid in batch:
					if component.has_entity(eid):
						component.remove_entity(eid)
		for eid in batch:
			_entity_ids_pool.free_entity_id(eid)
			if eid < _entities_to_archetypes.size():
				_entities_to_archetypes[eid] = -1

func get_entity_archetype(entity_id: int) -> ECSArchetype:
	if entity_id < 0 || entity_id >= _entities_to_archetypes.size():
		return null
	var archetype_hash: int = _entities_to_archetypes[entity_id]
	if _archetypes.has(archetype_hash):
		return _archetypes[archetype_hash]
	return null

## Возвращает все архетипы (для ECSQuery — итерация по подходящим без вызова match по каждой сущности).
func get_archetypes() -> Array:
	return _archetypes.values()

func has_component(entity_id: int, component_id: int) -> bool:
	if !_components.has(component_id):
		return false
	var component: ECSComponentBaseArray = _components[component_id]
	return component.has_entity(entity_id)

func add_component(entity_id: int, component_id: int) -> void:
	if entity_id < 0 || entity_id >= _entities_to_archetypes.size():
		return
	
	if has_component(entity_id, component_id):
		return  # Компонент уже есть
	
	if !_components.has(component_id):
		return  # Компонент не зарегистрирован
	
	# Получаем текущий архетип
	var old_archetype: ECSArchetype = get_entity_archetype(entity_id)
	if old_archetype == null:
		return

	# Буфер: новый набор компонентов с добавленным (Фаза D)
	_work_component_ids.clear()
	for c_id in old_archetype._component_ids:
		_work_component_ids.append(c_id)
	if component_id not in _work_component_ids:
		_work_component_ids.append(component_id)

	var new_archetype_hash: int = _work_bitmask_hash()
	if !_archetypes.has(new_archetype_hash):
		_archetypes[new_archetype_hash] = ECSArchetype.new(_work_bitmask._bits.duplicate(), _work_component_ids.duplicate())

	var new_archetype: ECSArchetype = _archetypes[new_archetype_hash]
	
	# Перемещаем сущность из старого архетипа в новый
	old_archetype.remove_entity(entity_id)
	new_archetype.add_entity(entity_id)
	
	# Обновляем связь entity_id -> archetype_hash
	_entities_to_archetypes[entity_id] = new_archetype_hash
	
	# Добавляем сущность в новый компонент
	var component: ECSComponentBaseArray = _components[component_id]
	if component != null:
		component.add_entity(entity_id)

func remove_component(entity_id: int, component_id: int) -> void:
	if entity_id < 0 || entity_id >= _entities_to_archetypes.size():
		return
	
	if !has_component(entity_id, component_id):
		return  # Компонента нет
	
	# Получаем текущий архетип
	var old_archetype: ECSArchetype = get_entity_archetype(entity_id)
	if old_archetype == null:
		return

	# Буфер: новый набор компонентов без удаляемого (Фаза D)
	_work_component_ids.clear()
	for c_id in old_archetype._component_ids:
		if c_id != component_id:
			_work_component_ids.append(c_id)

	if _work_component_ids.size() == 0:
		destroy_entity(entity_id)
		return

	var new_archetype_hash: int = _work_bitmask_hash()
	if !_archetypes.has(new_archetype_hash):
		_archetypes[new_archetype_hash] = ECSArchetype.new(_work_bitmask._bits.duplicate(), _work_component_ids.duplicate())

	var new_archetype: ECSArchetype = _archetypes[new_archetype_hash]
	
	# Перемещаем сущность из старого архетипа в новый
	old_archetype.remove_entity(entity_id)
	new_archetype.add_entity(entity_id)
	
	# Обновляем связь entity_id -> archetype_hash
	_entities_to_archetypes[entity_id] = new_archetype_hash
	
	# Удаляем сущность из компонента
	var component: ECSComponentBaseArray = _components[component_id]
	if component != null:
		component.remove_entity(entity_id)
