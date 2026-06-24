extends RefCounted
class_name ECSManager

## Контракт с компонентами: add_entity / remove_entity / has_entity. Размер чанка — ECSEntityIdsUtils.CHUNK_SIZE (см. ecs/DESIGN.md).
var _entity_ids_pool: ECSEntityIdsPool = ECSEntityIdsPool.new()

var _components: Dictionary[int, ECSComponentBaseArray] = {}
var _archetype_registry: Array[ECSArchetype] = []
var _archetype_id_to_key: Dictionary[int, PackedInt64Array] = {}
var _archetype_key_to_id: Dictionary = {}
var _entities_to_archetypes: PackedInt64Array = PackedInt64Array()
var _archetypes_version: int = 0

## Кэш для create_entity/create_entities: ключ PackedInt64Array (normalized ids) -> ECSArchetypeInfo.
var _archetype_cache: Dictionary = {}

## Кэш переходов архетипа: old_archetype_id -> component_id -> new_archetype_id.
var _add_transition_cache: Dictionary[int, Dictionary] = {}
var _remove_transition_cache: Dictionary[int, Dictionary] = {}

## Переиспользуемые буферы для add_component/remove_component (Фаза D).
var _work_component_ids: PackedInt64Array = PackedInt64Array()
var _work_bitmask: ECSBitMask = ECSBitMask.new(1)

## Scratch для destroy_entities: группировка по archetype_id без Dictionary.
var _destroy_entity_scratch: PackedInt64Array = PackedInt64Array()
var _destroy_archetype_id_scratch: PackedInt64Array = PackedInt64Array()
var _destroy_sort_indices: Array[int] = []
var _destroy_batch_scratch: PackedInt64Array = PackedInt64Array()

var _debug_scratch_guard: bool = OS.is_debug_build()
var _scratch_depth: int = 0

## Если true — GC пустых архетипов откладывается до flush_archetype_gc() (раннер вызывает в конце run).
var auto_gc_archetypes: bool = true
var _pending_archetype_gc: bool = false

func _init() -> void:
	pass

func get_archetypes_version() -> int:
	return _archetypes_version

func is_alive(entity_id: int) -> bool:
	return _entity_ids_pool.is_alive(entity_id)

func _scratch_enter(context: String) -> void:
	if _debug_scratch_guard:
		if _scratch_depth > 0:
			push_error("ECSManager: non-reentrant scratch (%s)" % context)
		_scratch_depth += 1

func _scratch_leave() -> void:
	if _debug_scratch_guard:
		_scratch_depth -= 1

func _get_archetype(archetype_id: int) -> ECSArchetype:
	if archetype_id < 0 || archetype_id >= _archetype_registry.size():
		return null
	return _archetype_registry[archetype_id]

func _evict_archetype_if_empty(archetype_id: int) -> void:
	if archetype_id < 0:
		return
	var archetype: ECSArchetype = _get_archetype(archetype_id)
	if archetype == null || archetype.get_live_count() > 0:
		return
	_evict_archetype(archetype_id)

func _schedule_archetype_gc() -> void:
	if !auto_gc_archetypes:
		return
	_pending_archetype_gc = true

## Сбрасывает отложенный GC: пустые архетипы и осиротевшие component chunks.
func flush_archetype_gc() -> void:
	gc_empty_archetypes()
	_evict_orphaned_component_chunks()
	_pending_archetype_gc = false

func flush_archetype_gc_if_pending() -> void:
	if _pending_archetype_gc:
		flush_archetype_gc()

func _evict_orphaned_component_chunks() -> void:
	for component_id in _components:
		var component: ECSComponentBaseArray = _components[component_id]
		var chunk_indices: Array[int] = component.get_chunk_indices()
		for chunk_index: int in chunk_indices:
			if !_is_component_chunk_referenced(component_id, chunk_index):
				component.evict_chunk_by_index(chunk_index)

func _is_component_chunk_referenced(component_id: int, chunk_index: int) -> bool:
	for archetype in _archetype_registry:
		if archetype == null:
			continue
		if component_id not in archetype._component_ids:
			continue
		if archetype.get_archetype_chunk_by_index(chunk_index) != null:
			return true
	return false

func _evict_archetype(archetype_id: int) -> void:
	if archetype_id < 0 || archetype_id >= _archetype_registry.size():
		return
	if _archetype_registry[archetype_id] == null:
		return
	var key: PackedInt64Array = _archetype_id_to_key.get(archetype_id, PackedInt64Array())
	if !key.is_empty():
		_archetype_key_to_id.erase(key)
	_archetype_id_to_key.erase(archetype_id)
	_archetype_registry[archetype_id] = null
	_add_transition_cache.erase(archetype_id)
	_remove_transition_cache.erase(archetype_id)
	_purge_transition_cache_references(archetype_id)
	_archetypes_version += 1

func _purge_transition_cache_references(archetype_id: int) -> void:
	for source_id: int in _add_transition_cache.keys():
		var inner: Dictionary = _add_transition_cache[source_id]
		for component_id in inner.keys():
			if inner[component_id] == archetype_id:
				inner.erase(component_id)
		if inner.is_empty():
			_add_transition_cache.erase(source_id)
	for source_id: int in _remove_transition_cache.keys():
		var inner: Dictionary = _remove_transition_cache[source_id]
		for component_id in inner.keys():
			if inner[component_id] == archetype_id:
				inner.erase(component_id)
		if inner.is_empty():
			_remove_transition_cache.erase(source_id)

func _prepare_work_bitmask() -> void:
	var max_id: int = 0
	for c_id in _work_component_ids:
		if c_id > max_id:
			max_id = c_id
	_work_bitmask.bit_resize(max_id + 1)
	_work_bitmask.bit_clear_all()
	for c_id in _work_component_ids:
		_work_bitmask.bit_set(c_id, true)

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

func _resolve_add_transition(old_archetype_id: int, component_id: int) -> int:
	if _add_transition_cache.has(old_archetype_id):
		var inner: Dictionary = _add_transition_cache[old_archetype_id]
		if inner.has(component_id):
			return inner[component_id]
	var old_archetype: ECSArchetype = _get_archetype(old_archetype_id)
	if old_archetype == null:
		return old_archetype_id
	_build_work_component_ids_after_add(old_archetype, component_id)
	_prepare_work_bitmask()
	var new_archetype_id: int = _register_archetype(_work_bitmask, _work_component_ids.duplicate())
	if !_add_transition_cache.has(old_archetype_id):
		_add_transition_cache[old_archetype_id] = {}
	var add_inner: Dictionary = _add_transition_cache[old_archetype_id]
	add_inner[component_id] = new_archetype_id
	_add_transition_cache[old_archetype_id] = add_inner
	return new_archetype_id

func _resolve_remove_transition(old_archetype_id: int, component_id: int) -> int:
	if _remove_transition_cache.has(old_archetype_id):
		var inner: Dictionary = _remove_transition_cache[old_archetype_id]
		if inner.has(component_id):
			return inner[component_id]
	var old_archetype: ECSArchetype = _get_archetype(old_archetype_id)
	if old_archetype == null:
		return old_archetype_id
	_build_work_component_ids_after_remove(old_archetype, component_id)
	if _work_component_ids.is_empty():
		return -1
	_prepare_work_bitmask()
	var new_archetype_id: int = _register_archetype(_work_bitmask, _work_component_ids.duplicate())
	if !_remove_transition_cache.has(old_archetype_id):
		_remove_transition_cache[old_archetype_id] = {}
	var remove_inner: Dictionary = _remove_transition_cache[old_archetype_id]
	remove_inner[component_id] = new_archetype_id
	_remove_transition_cache[old_archetype_id] = remove_inner
	return new_archetype_id

func _get_or_create_archetype_info_packed(component_ids: PackedInt64Array) -> ECSArchetypeInfo:
	var normalized_ids: PackedInt64Array = _normalize_component_ids(component_ids)
	var key: PackedInt64Array = ECSArchetypeKey.make_from_packed_ids(normalized_ids)
	if _archetype_cache.has(key):
		return _archetype_cache[key]
	var max_component_id: int = 0
	for component_id in normalized_ids:
		if component_id > max_component_id:
			max_component_id = component_id
	var bits: ECSBitMask = ECSBitMask.new(max_component_id + 1)
	for component_id in normalized_ids:
		bits.bit_set(component_id, true)
	var info: ECSArchetypeInfo = ECSArchetypeInfo.new(bits, normalized_ids.duplicate())
	_archetype_cache[key] = info
	return info

func _register_archetype(bits: ECSBitMask, packed_component_ids: PackedInt64Array) -> int:
	var key: PackedInt64Array = ECSArchetypeKey.make_from_packed_ids(packed_component_ids)
	if _archetype_key_to_id.has(key):
		return _archetype_key_to_id[key]
	var archetype_id: int = _archetype_registry.size()
	_archetype_registry.append(ECSArchetype.new(bits._bits, packed_component_ids))
	_archetype_id_to_key[archetype_id] = key
	_archetype_key_to_id[key] = archetype_id
	_archetypes_version += 1
	return archetype_id

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
	_register_archetype(info.bitmask, info.packed)

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
	var archetype_id: int = _register_archetype(info.bitmask, info.packed)
	var archetype: ECSArchetype = _get_archetype(archetype_id)
	archetype.add_entity(entity_id)
	var entity_index: int = _entity_index(entity_id)
	_ensure_entity_mapping_capacity(entity_index)
	_entities_to_archetypes[entity_index] = archetype_id
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
	var archetype_id: int = _register_archetype(info.bitmask, info.packed)
	var archetype: ECSArchetype = _get_archetype(archetype_id)
	for i in range(count):
		var entity_id: int = _entity_ids_pool.get_next_entity_id()
		entity_ids[i] = entity_id
		archetype.add_entity(entity_id)
		var entity_index: int = _entity_index(entity_id)
		_ensure_entity_mapping_capacity(entity_index)
		_entities_to_archetypes[entity_index] = archetype_id
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
	var archetype_id: int = _entities_to_archetypes[entity_index]
	var archetype: ECSArchetype = _get_archetype(archetype_id)
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
	_schedule_archetype_gc()

func destroy_entities_packed(entity_ids: PackedInt64Array) -> void:
	if entity_ids.is_empty():
		return
	_scratch_enter("destroy_entities_packed")
	var estimated: int = entity_ids.size()
	_destroy_entity_scratch.resize(estimated)
	_destroy_archetype_id_scratch.resize(estimated)
	var write_index: int = 0
	var first_archetype_id: int = 0
	var single_archetype: bool = true
	var has_any: bool = false
	for entity_id in entity_ids:
		if !is_alive(entity_id):
			continue
		var entity_index: int = _entity_index(entity_id)
		if entity_index < 0 || entity_index >= _entities_to_archetypes.size():
			continue
		var archetype_id: int = _entities_to_archetypes[entity_index]
		if archetype_id < 0:
			continue
		if has_any:
			if archetype_id != first_archetype_id:
				single_archetype = false
		else:
			first_archetype_id = archetype_id
			has_any = true
		_destroy_entity_scratch[write_index] = entity_id
		_destroy_archetype_id_scratch[write_index] = archetype_id
		write_index += 1
	var valid_count: int = write_index
	if valid_count == 0:
		_scratch_leave()
		return
	if valid_count < estimated:
		_destroy_entity_scratch.resize(valid_count)
		_destroy_archetype_id_scratch.resize(valid_count)
	if single_archetype:
		_destroy_archetype_batch(first_archetype_id, _destroy_entity_scratch)
		_scratch_leave()
		return
	_destroy_sort_indices.resize(valid_count)
	for i in range(valid_count):
		_destroy_sort_indices[i] = i
	_destroy_sort_indices.sort_custom(func(a: int, b: int) -> bool:
		return _destroy_archetype_id_scratch[a] < _destroy_archetype_id_scratch[b]
	)
	var cursor: int = 0
	while cursor < valid_count:
		var archetype_id: int = _destroy_archetype_id_scratch[_destroy_sort_indices[cursor]]
		var range_start: int = cursor
		cursor += 1
		while cursor < valid_count && _destroy_archetype_id_scratch[_destroy_sort_indices[cursor]] == archetype_id:
			cursor += 1
		var range_size: int = cursor - range_start
		_destroy_batch_scratch.resize(range_size)
		for i in range(range_size):
			_destroy_batch_scratch[i] = _destroy_entity_scratch[_destroy_sort_indices[range_start + i]]
		_destroy_archetype_batch(archetype_id, _destroy_batch_scratch)
	_scratch_leave()

## Внешний API: Array[int], PackedInt64Array создаётся внутри.
func destroy_entities(entity_ids: Array[int]) -> void:
	destroy_entities_packed(_packed_from_array(entity_ids))

func _destroy_archetype_batch(archetype_id: int, batch: PackedInt64Array) -> void:
	if batch.is_empty():
		return
	var archetype: ECSArchetype = _get_archetype(archetype_id)
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
	_schedule_archetype_gc()

func get_entity_archetype(entity_id: int) -> ECSArchetype:
	if !is_alive(entity_id):
		return null
	var entity_index: int = _entity_index(entity_id)
	if entity_index < 0 || entity_index >= _entities_to_archetypes.size():
		return null
	var archetype_id: int = _entities_to_archetypes[entity_index]
	return _get_archetype(archetype_id)

func get_archetypes() -> Array[ECSArchetype]:
	var result: Array[ECSArchetype] = []
	for archetype in _archetype_registry:
		if archetype != null:
			result.append(archetype)
	return result

func get_archetype_registry_size() -> int:
	return _archetype_registry.size()

func count_live_archetypes() -> int:
	var count: int = 0
	for archetype in _archetype_registry:
		if archetype != null && archetype.get_live_count() > 0:
			count += 1
	return count

func count_registered_archetypes() -> int:
	var count: int = 0
	for archetype in _archetype_registry:
		if archetype != null:
			count += 1
	return count

func reset() -> void:
	var to_destroy: PackedInt64Array = PackedInt64Array()
	for archetype in _archetype_registry:
		if archetype == null:
			continue
		for chunk_index: int in archetype.get_chunk_indices():
			var chunk: ECSArchetypeChunk = archetype.get_archetype_chunk_by_index(chunk_index)
			if chunk == null:
				continue
			var dense: PackedInt64Array = chunk.get_dense_entities()
			var entity_count: int = chunk.get_entity_count()
			for i in range(entity_count):
				to_destroy.append(dense[i])
	if !to_destroy.is_empty():
		destroy_entities_packed(to_destroy)
	for component: ECSComponentBaseArray in _components.values():
		component.clear()
	_archetype_registry.clear()
	_archetype_id_to_key.clear()
	_archetype_key_to_id.clear()
	_archetype_cache.clear()
	_add_transition_cache.clear()
	_remove_transition_cache.clear()
	_entities_to_archetypes = PackedInt64Array()
	_entity_ids_pool = ECSEntityIdsPool.new()
	_pending_archetype_gc = false
	_archetypes_version += 1

func gc_empty_archetypes() -> void:
	var to_evict: Array[int] = []
	for archetype_id in range(_archetype_registry.size()):
		var archetype: ECSArchetype = _archetype_registry[archetype_id]
		if archetype != null && archetype.get_live_count() == 0:
			to_evict.append(archetype_id)
	for archetype_id: int in to_evict:
		_evict_archetype(archetype_id)

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
	var old_archetype_id: int = _entities_to_archetypes[entity_index]
	var new_archetype_id: int = _resolve_add_transition(old_archetype_id, component_id)
	var new_archetype: ECSArchetype = _get_archetype(new_archetype_id)
	old_archetype.remove_entity(entity_id)
	new_archetype.add_entity(entity_id)
	_entities_to_archetypes[entity_index] = new_archetype_id
	var component: ECSComponentBaseArray = _components[component_id]
	component.add_entity(entity_id)
	_schedule_archetype_gc()

func remove_component(entity_id: int, component_id: int) -> void:
	if !is_alive(entity_id):
		return
	if !has_component(entity_id, component_id):
		return
	var old_archetype: ECSArchetype = get_entity_archetype(entity_id)
	if old_archetype == null:
		return
	var entity_index: int = _entity_index(entity_id)
	var old_archetype_id: int = _entities_to_archetypes[entity_index]
	var new_archetype_id: int = _resolve_remove_transition(old_archetype_id, component_id)
	if new_archetype_id < 0:
		destroy_entity(entity_id)
		return
	var new_archetype: ECSArchetype = _get_archetype(new_archetype_id)
	old_archetype.remove_entity(entity_id)
	new_archetype.add_entity(entity_id)
	_entities_to_archetypes[entity_index] = new_archetype_id
	var component: ECSComponentBaseArray = _components[component_id]
	component.remove_entity(entity_id)
	_schedule_archetype_gc()
