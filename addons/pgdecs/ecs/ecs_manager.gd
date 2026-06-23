extends RefCounted
class_name ECSManager

## Контракт с компонентами: add_entity / remove_entity / has_entity. Размер чанка — ECSEntityIdsUtils.CHUNK_SIZE (см. ecs/DESIGN.md).
var _entity_ids_pool: ECSEntityIdsPool = ECSEntityIdsPool.new()

var _components: Dictionary[int, ECSComponentBaseArray] = {}
var _archetypes: Dictionary[int, ECSArchetype] = {}
var _entities_to_archetypes: PackedInt64Array = PackedInt64Array()
var _archetypes_version: int = 0

## Кэш для create_entity/create_entities: ключ bit_hash -> ECSArchetypeInfo.
var _archetype_cache: Dictionary[int, ECSArchetypeInfo] = {}

## Переиспользуемые буферы для add_component/remove_component (Фаза D).
var _work_component_ids: PackedInt64Array = PackedInt64Array()
var _work_bitmask: ECSBitMask = ECSBitMask.new(1)

func _init() -> void:
	pass

func get_archetypes_version() -> int:
	return _archetypes_version

func is_alive(entity_id: int) -> bool:
	return _entity_ids_pool.is_alive(entity_id)

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

func _get_or_create_archetype_info_packed(component_ids: PackedInt64Array) -> ECSArchetypeInfo:
	var max_component_id: int = 0
	for component_id in component_ids:
		if component_id > max_component_id:
			max_component_id = component_id
	var bits: ECSBitMask = ECSBitMask.new(max_component_id + 1)
	for component_id in component_ids:
		bits.bit_set(component_id, true)
	var archetype_hash: int = bits.bit_hash()
	if _archetype_cache.has(archetype_hash):
		return _archetype_cache[archetype_hash]
	var info: ECSArchetypeInfo = ECSArchetypeInfo.new(bits, component_ids.duplicate())
	_archetype_cache[archetype_hash] = info
	return info

func _register_archetype(archetype_hash: int, bits: ECSBitMask, packed_component_ids: PackedInt64Array) -> ECSArchetype:
	if !_archetypes.has(archetype_hash):
		_archetypes[archetype_hash] = ECSArchetype.new(bits._bits, packed_component_ids)
		_archetypes_version += 1
	return _archetypes[archetype_hash]

func _entity_index(entity_id: int) -> int:
	return ECSEntityHandle.index_of(entity_id)

func _ensure_entity_mapping_capacity(entity_index: int) -> void:
	if entity_index >= _entities_to_archetypes.size():
		_entities_to_archetypes.resize(entity_index + 1)

func register_component(component_id: int, component_type: Variant.Type) -> void:
	if _components.has(component_id):
		push_error("ECSManager: component %d already registered" % component_id)
		return
	var component: ECSComponentBaseArray = ECSComponentFactory.create_component(component_type)
	if component == null:
		push_error("ECSManager: unknown component type for id %d" % component_id)
		return
	_components[component_id] = component

## Предрасчёт архетипа для набора компонентов (кэш + создание архетипа).
func precache_archetype_packed(component_ids: PackedInt64Array) -> void:
	var info: ECSArchetypeInfo = _get_or_create_archetype_info_packed(component_ids)
	_register_archetype(info.bitmask.bit_hash(), info.bitmask, info.packed)

func get_component_array(component_id: int) -> ECSComponentBaseArray:
	return _components.get(component_id, null)

func create_entity_packed(component_ids: PackedInt64Array) -> int:
	for component_id in component_ids:
		if !_components.has(component_id):
			push_error("ECSManager: unregistered component %d in create_entity" % component_id)
			return 0
	var entity_id: int = _entity_ids_pool.get_next_entity_id()
	var info: ECSArchetypeInfo = _get_or_create_archetype_info_packed(component_ids)
	var archetype_hash: int = info.bitmask.bit_hash()
	var archetype: ECSArchetype = _register_archetype(archetype_hash, info.bitmask, info.packed)
	archetype.add_entity(entity_id)
	var entity_index: int = _entity_index(entity_id)
	_ensure_entity_mapping_capacity(entity_index)
	_entities_to_archetypes[entity_index] = archetype_hash
	for component_id in info.packed:
		var component: ECSComponentBaseArray = _components[component_id]
		component.add_entity(entity_id)
	return entity_id

func create_entities_packed(count: int, component_ids: PackedInt64Array) -> PackedInt64Array:
	if count <= 0:
		return PackedInt64Array()
	for component_id in component_ids:
		if !_components.has(component_id):
			push_error("ECSManager: unregistered component %d in create_entities" % component_id)
			return PackedInt64Array()
	var entity_ids: PackedInt64Array = PackedInt64Array()
	entity_ids.resize(count)
	var info: ECSArchetypeInfo = _get_or_create_archetype_info_packed(component_ids)
	var archetype_hash: int = info.bitmask.bit_hash()
	var archetype: ECSArchetype = _register_archetype(archetype_hash, info.bitmask, info.packed)
	for i in range(count):
		var entity_id: int = _entity_ids_pool.get_next_entity_id()
		entity_ids[i] = entity_id
		archetype.add_entity(entity_id)
		var entity_index: int = _entity_index(entity_id)
		_ensure_entity_mapping_capacity(entity_index)
		_entities_to_archetypes[entity_index] = archetype_hash
	for component_id in info.packed:
		var component: ECSComponentBaseArray = _components[component_id]
		component.add_entities_batch(entity_ids)
	return entity_ids

func destroy_entity(entity_id: int) -> void:
	if !is_alive(entity_id):
		return
	var entity_index: int = _entity_index(entity_id)
	if entity_index < 0 || entity_index >= _entities_to_archetypes.size():
		return
	var archetype_hash: int = _entities_to_archetypes[entity_index]
	var archetype: ECSArchetype = _archetypes.get(archetype_hash, null)
	if archetype != null:
		archetype.remove_entity(entity_id)
	var component_ids_to_clear: PackedInt64Array
	if archetype != null:
		component_ids_to_clear = archetype._component_ids
	else:
		component_ids_to_clear = PackedInt64Array(_components.keys())
	for component_id in component_ids_to_clear:
		var component: ECSComponentBaseArray = _components.get(component_id, null)
		if component != null:
			component.remove_entity(entity_id)
	_entity_ids_pool.free_entity_id(entity_id)
	_entities_to_archetypes[entity_index] = -1

func destroy_entities(entity_ids: PackedInt64Array) -> void:
	if entity_ids.is_empty():
		return
	var by_archetype: Dictionary[int, PackedInt64Array] = {}
	for entity_id in entity_ids:
		if !is_alive(entity_id):
			continue
		var entity_index: int = _entity_index(entity_id)
		if entity_index < 0 || entity_index >= _entities_to_archetypes.size():
			continue
		var archetype_hash: int = _entities_to_archetypes[entity_index]
		if archetype_hash < 0:
			continue
		if !by_archetype.has(archetype_hash):
			by_archetype[archetype_hash] = PackedInt64Array()
		by_archetype[archetype_hash].append(entity_id)
	for archetype_hash in by_archetype:
		var batch: PackedInt64Array = by_archetype[archetype_hash]
		var archetype: ECSArchetype = _archetypes.get(archetype_hash, null)
		if archetype == null:
			for entity_id in batch:
				for component_id in _components:
					var component: ECSComponentBaseArray = _components[component_id]
					component.remove_entity(entity_id)
				_entity_ids_pool.free_entity_id(entity_id)
				_entities_to_archetypes[_entity_index(entity_id)] = -1
			continue
		for entity_id in batch:
			archetype.remove_entity(entity_id)
		for component_id in archetype._component_ids:
			var component: ECSComponentBaseArray = _components.get(component_id, null)
			if component != null:
				component.remove_entities_batch(batch)
		for entity_id in batch:
			_entity_ids_pool.free_entity_id(entity_id)
			_entities_to_archetypes[_entity_index(entity_id)] = -1

func get_entity_archetype(entity_id: int) -> ECSArchetype:
	if !is_alive(entity_id):
		return null
	var entity_index: int = _entity_index(entity_id)
	if entity_index < 0 || entity_index >= _entities_to_archetypes.size():
		return null
	var archetype_hash: int = _entities_to_archetypes[entity_index]
	return _archetypes.get(archetype_hash, null)

func get_archetypes() -> Array[ECSArchetype]:
	var result: Array[ECSArchetype] = []
	for archetype in _archetypes.values():
		result.append(archetype)
	return result

func has_component(entity_id: int, component_id: int) -> bool:
	if !is_alive(entity_id):
		return false
	var archetype: ECSArchetype = get_entity_archetype(entity_id)
	if archetype == null:
		return false
	if !archetype.get_bitmask().bit_test(component_id):
		return false
	return archetype.has_entity(entity_id)

func add_component(entity_id: int, component_id: int) -> void:
	if !is_alive(entity_id):
		return
	if has_component(entity_id, component_id):
		return
	if !_components.has(component_id):
		push_error("ECSManager: unregistered component %d in add_component" % component_id)
		return
	var old_archetype: ECSArchetype = get_entity_archetype(entity_id)
	if old_archetype == null:
		return
	_work_component_ids.clear()
	for c_id in old_archetype._component_ids:
		_work_component_ids.append(c_id)
	if component_id not in _work_component_ids:
		_work_component_ids.append(component_id)
	var new_archetype_hash: int = _work_bitmask_hash()
	var new_archetype: ECSArchetype = _register_archetype(new_archetype_hash, _work_bitmask, _work_component_ids.duplicate())
	old_archetype.remove_entity(entity_id)
	new_archetype.add_entity(entity_id)
	_entities_to_archetypes[_entity_index(entity_id)] = new_archetype_hash
	var component: ECSComponentBaseArray = _components[component_id]
	component.add_entity(entity_id)

func remove_component(entity_id: int, component_id: int) -> void:
	if !is_alive(entity_id):
		return
	if !has_component(entity_id, component_id):
		return
	var old_archetype: ECSArchetype = get_entity_archetype(entity_id)
	if old_archetype == null:
		return
	_work_component_ids.clear()
	for c_id in old_archetype._component_ids:
		if c_id != component_id:
			_work_component_ids.append(c_id)
	if _work_component_ids.size() == 0:
		destroy_entity(entity_id)
		return
	var new_archetype_hash: int = _work_bitmask_hash()
	var new_archetype: ECSArchetype = _register_archetype(new_archetype_hash, _work_bitmask, _work_component_ids.duplicate())
	old_archetype.remove_entity(entity_id)
	new_archetype.add_entity(entity_id)
	_entities_to_archetypes[_entity_index(entity_id)] = new_archetype_hash
	var component: ECSComponentBaseArray = _components[component_id]
	component.remove_entity(entity_id)
