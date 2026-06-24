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

## Кэш переходов архетипа: old_hash -> component_id -> new_hash.
var _add_transition_cache: Dictionary[int, Dictionary] = {}
var _remove_transition_cache: Dictionary[int, Dictionary] = {}

## Переиспользуемые буферы для add_component/remove_component (Фаза D).
var _work_component_ids: PackedInt64Array = PackedInt64Array()
var _work_bitmask: ECSBitMask = ECSBitMask.new(1)

## Scratch для destroy_entities: группировка по archetype hash без Dictionary.
var _destroy_entity_scratch: PackedInt64Array = PackedInt64Array()
var _destroy_hash_scratch: PackedInt64Array = PackedInt64Array()
var _destroy_sort_indices: Array[int] = []
var _destroy_batch_scratch: PackedInt64Array = PackedInt64Array()

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

## Sort + unique для стабильных архетипов и кэшей.
func _normalize_component_ids(component_ids: PackedInt64Array) -> PackedInt64Array:
	if component_ids.is_empty():
		return PackedInt64Array()
	var sorted_ids: PackedInt64Array = component_ids.duplicate()
	sorted_ids.sort()
	var unique_ids: PackedInt64Array = PackedInt64Array()
	var has_prev: bool = false
	var prev_id: int = 0
	for component_id in sorted_ids:
		if !has_prev || component_id != prev_id:
			unique_ids.append(component_id)
			prev_id = component_id
			has_prev = true
	return unique_ids

func _packed_from_array(component_ids: Array[int]) -> PackedInt64Array:
	return PackedInt64Array(component_ids)

func _build_work_component_ids_after_add(old_archetype: ECSArchetype, component_id: int) -> void:
	var temp_ids: PackedInt64Array = PackedInt64Array()
	for c_id in old_archetype._component_ids:
		temp_ids.append(c_id)
	if component_id not in temp_ids:
		temp_ids.append(component_id)
	_work_component_ids = _normalize_component_ids(temp_ids)

func _build_work_component_ids_after_remove(old_archetype: ECSArchetype, component_id: int) -> void:
	var temp_ids: PackedInt64Array = PackedInt64Array()
	for c_id in old_archetype._component_ids:
		if c_id != component_id:
			temp_ids.append(c_id)
	_work_component_ids = _normalize_component_ids(temp_ids)

func _resolve_add_transition(old_hash: int, component_id: int) -> int:
	if _add_transition_cache.has(old_hash):
		var inner: Dictionary = _add_transition_cache[old_hash]
		if inner.has(component_id):
			return inner[component_id]
	var old_archetype: ECSArchetype = _archetypes.get(old_hash, null)
	if old_archetype == null:
		return old_hash
	_build_work_component_ids_after_add(old_archetype, component_id)
	var new_hash: int = _work_bitmask_hash()
	_register_archetype(new_hash, _work_bitmask, _work_component_ids.duplicate())
	if !_add_transition_cache.has(old_hash):
		_add_transition_cache[old_hash] = {}
	var add_inner: Dictionary = _add_transition_cache[old_hash]
	add_inner[component_id] = new_hash
	_add_transition_cache[old_hash] = add_inner
	return new_hash

func _resolve_remove_transition(old_hash: int, component_id: int) -> int:
	if _remove_transition_cache.has(old_hash):
		var inner: Dictionary = _remove_transition_cache[old_hash]
		if inner.has(component_id):
			return inner[component_id]
	var old_archetype: ECSArchetype = _archetypes.get(old_hash, null)
	if old_archetype == null:
		return old_hash
	_build_work_component_ids_after_remove(old_archetype, component_id)
	if _work_component_ids.is_empty():
		return -1
	var new_hash: int = _work_bitmask_hash()
	_register_archetype(new_hash, _work_bitmask, _work_component_ids.duplicate())
	if !_remove_transition_cache.has(old_hash):
		_remove_transition_cache[old_hash] = {}
	var remove_inner: Dictionary = _remove_transition_cache[old_hash]
	remove_inner[component_id] = new_hash
	_remove_transition_cache[old_hash] = remove_inner
	return new_hash

func _get_or_create_archetype_info_packed(component_ids: PackedInt64Array) -> ECSArchetypeInfo:
	var normalized_ids: PackedInt64Array = _normalize_component_ids(component_ids)
	var max_component_id: int = 0
	for component_id in normalized_ids:
		if component_id > max_component_id:
			max_component_id = component_id
	var bits: ECSBitMask = ECSBitMask.new(max_component_id + 1)
	for component_id in normalized_ids:
		bits.bit_set(component_id, true)
	var archetype_hash: int = bits.bit_hash()
	if _archetype_cache.has(archetype_hash):
		return _archetype_cache[archetype_hash]
	var info: ECSArchetypeInfo = ECSArchetypeInfo.new(bits, normalized_ids.duplicate())
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
	var normalized_ids: PackedInt64Array = _normalize_component_ids(component_ids)
	if normalized_ids.is_empty():
		return
	var info: ECSArchetypeInfo = _get_or_create_archetype_info_packed(normalized_ids)
	_register_archetype(info.bitmask.bit_hash(), info.bitmask, info.packed)

## Внешний API: Array[int], PackedInt64Array создаётся внутри.
func precache_archetype(component_ids: Array[int]) -> void:
	precache_archetype_packed(_packed_from_array(component_ids))

## Предрасчёт + нормализованный PackedInt64Array для hot-path (create_entity_packed).
func prepare_archetype(component_ids: Array[int]) -> PackedInt64Array:
	var packed: PackedInt64Array = _normalize_component_ids(_packed_from_array(component_ids))
	if packed.is_empty():
		return PackedInt64Array()
	precache_archetype_packed(packed)
	return packed

func get_component_array(component_id: int) -> ECSComponentBaseArray:
	return _components.get(component_id, null)

func create_entity_packed(component_ids: PackedInt64Array) -> int:
	var normalized_ids: PackedInt64Array = _normalize_component_ids(component_ids)
	if normalized_ids.is_empty():
		push_error("ECSManager: empty component set in create_entity")
		return 0
	for component_id in normalized_ids:
		if !_components.has(component_id):
			push_error("ECSManager: unregistered component %d in create_entity" % component_id)
			return 0
	var entity_id: int = _entity_ids_pool.get_next_entity_id()
	var info: ECSArchetypeInfo = _get_or_create_archetype_info_packed(normalized_ids)
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

## Внешний API: Array[int], PackedInt64Array создаётся внутри.
func create_entity(component_ids: Array[int]) -> int:
	return create_entity_packed(_packed_from_array(component_ids))

func create_entities_packed(count: int, component_ids: PackedInt64Array) -> PackedInt64Array:
	if count <= 0:
		return PackedInt64Array()
	var normalized_ids: PackedInt64Array = _normalize_component_ids(component_ids)
	if normalized_ids.is_empty():
		push_error("ECSManager: empty component set in create_entities")
		return PackedInt64Array()
	for component_id in normalized_ids:
		if !_components.has(component_id):
			push_error("ECSManager: unregistered component %d in create_entities" % component_id)
			return PackedInt64Array()
	var entity_ids: PackedInt64Array = PackedInt64Array()
	entity_ids.resize(count)
	var info: ECSArchetypeInfo = _get_or_create_archetype_info_packed(normalized_ids)
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

## Внешний API: Array[int], PackedInt64Array создаётся внутри.
func create_entities(count: int, component_ids: Array[int]) -> PackedInt64Array:
	return create_entities_packed(count, _packed_from_array(component_ids))

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

func destroy_entities_packed(entity_ids: PackedInt64Array) -> void:
	if entity_ids.is_empty():
		return
	var estimated: int = entity_ids.size()
	_destroy_entity_scratch.resize(estimated)
	_destroy_hash_scratch.resize(estimated)
	var write_index: int = 0
	var first_hash: int = 0
	var single_archetype: bool = true
	var has_any: bool = false
	for entity_id in entity_ids:
		if !is_alive(entity_id):
			continue
		var entity_index: int = _entity_index(entity_id)
		if entity_index < 0 || entity_index >= _entities_to_archetypes.size():
			continue
		var archetype_hash: int = _entities_to_archetypes[entity_index]
		if archetype_hash < 0:
			continue
		if has_any:
			if archetype_hash != first_hash:
				single_archetype = false
		else:
			first_hash = archetype_hash
			has_any = true
		_destroy_entity_scratch[write_index] = entity_id
		_destroy_hash_scratch[write_index] = archetype_hash
		write_index += 1
	var valid_count: int = write_index
	if valid_count == 0:
		return
	if valid_count < estimated:
		_destroy_entity_scratch.resize(valid_count)
		_destroy_hash_scratch.resize(valid_count)
	if single_archetype:
		_destroy_archetype_batch(first_hash, _destroy_entity_scratch)
		return
	_destroy_sort_indices.resize(valid_count)
	for i in range(valid_count):
		_destroy_sort_indices[i] = i
	_destroy_sort_indices.sort_custom(func(a: int, b: int) -> bool:
		return _destroy_hash_scratch[a] < _destroy_hash_scratch[b]
	)
	var cursor: int = 0
	while cursor < valid_count:
		var archetype_hash: int = _destroy_hash_scratch[_destroy_sort_indices[cursor]]
		var range_start: int = cursor
		cursor += 1
		while cursor < valid_count && _destroy_hash_scratch[_destroy_sort_indices[cursor]] == archetype_hash:
			cursor += 1
		var range_size: int = cursor - range_start
		_destroy_batch_scratch.resize(range_size)
		for i in range(range_size):
			_destroy_batch_scratch[i] = _destroy_entity_scratch[_destroy_sort_indices[range_start + i]]
		_destroy_archetype_batch(archetype_hash, _destroy_batch_scratch)

## Внешний API: Array[int], PackedInt64Array создаётся внутри.
func destroy_entities(entity_ids: Array[int]) -> void:
	destroy_entities_packed(_packed_from_array(entity_ids))

func _destroy_archetype_batch(archetype_hash: int, batch: PackedInt64Array) -> void:
	if batch.is_empty():
		return
	var archetype: ECSArchetype = _archetypes.get(archetype_hash, null)
	if archetype == null:
		for entity_id in batch:
			for component_id in _components:
				var component: ECSComponentBaseArray = _components[component_id]
				component.remove_entity(entity_id)
			_entity_ids_pool.free_entity_id(entity_id)
			_entities_to_archetypes[_entity_index(entity_id)] = -1
		return
	archetype.remove_entities_batch(batch)
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
	var entity_index: int = _entity_index(entity_id)
	var old_hash: int = _entities_to_archetypes[entity_index]
	var new_archetype_hash: int = _resolve_add_transition(old_hash, component_id)
	var new_archetype: ECSArchetype = _archetypes[new_archetype_hash]
	old_archetype.remove_entity(entity_id)
	new_archetype.add_entity(entity_id)
	_entities_to_archetypes[entity_index] = new_archetype_hash
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
	var entity_index: int = _entity_index(entity_id)
	var old_hash: int = _entities_to_archetypes[entity_index]
	var new_archetype_hash: int = _resolve_remove_transition(old_hash, component_id)
	if new_archetype_hash < 0:
		destroy_entity(entity_id)
		return
	var new_archetype: ECSArchetype = _archetypes[new_archetype_hash]
	old_archetype.remove_entity(entity_id)
	new_archetype.add_entity(entity_id)
	_entities_to_archetypes[entity_index] = new_archetype_hash
	var component: ECSComponentBaseArray = _components[component_id]
	component.remove_entity(entity_id)
