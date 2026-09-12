extends RefCounted
class_name ECSManager

class _ArchetypeCacheEntry extends RefCounted:
	var key: PackedInt64Array
	var info: ECSArchetypeInfo
	var archetype_id: int = -1

## Контракт с компонентами: add_entity / remove_entity / has_entity. Размер чанка — ECSEntityIdsUtils.CHUNK_SIZE (см. ecs/DESIGN.md).
var _entity_ids_pool: ECSEntityIdsPool = ECSEntityIdsPool.new()

var _components: Dictionary[int, ECSComponentBaseArray] = {}
## Marker component ids: membership only in archetype bitmask, no SoA storage.
var _tags: Dictionary[int, bool] = {}
var _archetype_registry: Array[ECSArchetype] = []
## Компактный список без null-слотов (для query cache и GC).
var _registered_archetypes: Array[ECSArchetype] = []
var _archetype_id_to_key: Dictionary[int, PackedInt64Array] = {}
## hash -> Array[_ArchetypeCacheEntry]. Variant value — ограничение GDScript typed Dictionary.
var _archetype_cache_buckets: Dictionary[int, Variant] = {}
var _entities_to_archetypes: PackedInt64Array = PackedInt64Array()
var _archetypes_version: int = 0

## Кэш переходов архетипа: old_archetype_id -> component_id -> new_archetype_id.
var _add_transition_cache: Dictionary[int, Dictionary] = {}
var _remove_transition_cache: Dictionary[int, Dictionary] = {}

## Переиспользуемые буферы для add_component/remove_component (Фаза D).
var _work_component_ids: PackedInt64Array = PackedInt64Array()
var _work_bitmask: ECSBitMask = ECSBitMask.new(1)

## Scratch для destroy_entities: single-archetype — packed; multi — buckets по archetype_id.
var _destroy_entity_scratch: PackedInt64Array = PackedInt64Array()
var _destroy_buckets: Dictionary[int, PackedInt64Array] = {}
var _destroy_touched_ids: Array[int] = []

var _debug_scratch_guard: bool = OS.is_debug_build()
var _scratch_depth: int = 0

## Если true — GC пустых архетипов откладывается до flush_archetype_gc() (раннер вызывает в конце run).
var auto_gc_archetypes: bool = true
var _pending_archetype_gc: bool = false
## archetype_id с live_count == 0 после structural-мутации (точечный eviction вместо полного скана).
var _gc_empty_archetype_candidates: Dictionary[int, bool] = {}
## Было удаление записи chunk_index из map архетипа — возможны осиротевшие component chunks.
var _gc_component_chunks_dirty: bool = false
var _gc_orphan_chunks_scratch: Array[int] = []

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

func _note_archetype_gc_work(archetype_id: int, archetype_chunk_removed: bool) -> void:
	if !auto_gc_archetypes:
		return
	_pending_archetype_gc = true
	if archetype_id >= 0:
		var archetype: ECSArchetype = _get_archetype(archetype_id)
		if archetype != null && archetype.get_live_count() == 0:
			_gc_empty_archetype_candidates[archetype_id] = true
	if archetype_chunk_removed:
		_gc_component_chunks_dirty = true

## Сбрасывает отложенный GC: пустые архетипы и осиротевшие component chunks (только при необходимости).
func flush_archetype_gc() -> void:
	if !_pending_archetype_gc:
		return
	var archetypes_evicted: bool = false
	if !_gc_empty_archetype_candidates.is_empty():
		for archetype_id: int in _gc_empty_archetype_candidates:
			var before_version: int = _archetypes_version
			_evict_archetype_if_empty(archetype_id)
			if _archetypes_version != before_version:
				archetypes_evicted = true
		_gc_empty_archetype_candidates.clear()
	elif count_registered_archetypes() > count_live_archetypes():
		gc_empty_archetypes()
		archetypes_evicted = true
	if _gc_component_chunks_dirty || archetypes_evicted:
		_evict_orphaned_component_chunks()
	_pending_archetype_gc = false
	_gc_component_chunks_dirty = false

func flush_archetype_gc_if_pending() -> void:
	if _pending_archetype_gc:
		flush_archetype_gc()

func _evict_orphaned_component_chunks() -> void:
	for component_id in _components:
		var component: ECSComponentBaseArray = _components[component_id]
		_gc_orphan_chunks_scratch.clear()
		component.for_each_chunk_index(func(chunk_index: int) -> void:
			if !_is_component_chunk_referenced(component_id, chunk_index):
				_gc_orphan_chunks_scratch.append(chunk_index)
		)
		for chunk_index in _gc_orphan_chunks_scratch:
			component.evict_chunk_by_index(chunk_index)

func _is_component_chunk_referenced(component_id: int, chunk_index: int) -> bool:
	for archetype in _registered_archetypes:
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
		_remove_archetype_cache_entry(key)
	var evicted: ECSArchetype = _archetype_registry[archetype_id]
	for i in range(_registered_archetypes.size()):
		if _registered_archetypes[i] == evicted:
			_registered_archetypes.remove_at(i)
			break
	_archetype_id_to_key.erase(archetype_id)
	_archetype_registry[archetype_id] = null
	_add_transition_cache.erase(archetype_id)
	_remove_transition_cache.erase(archetype_id)
	_purge_transition_cache_references(archetype_id)
	_archetypes_version += 1

func _purge_transition_cache_references(archetype_id: int) -> void:
	for source_id: int in _add_transition_cache.keys():
		var inner: Dictionary[int, int] = _add_transition_cache[source_id]
		for component_id: int in inner.keys():
			if inner[component_id] == archetype_id:
				inner.erase(component_id)
		if inner.is_empty():
			_add_transition_cache.erase(source_id)
	for source_id: int in _remove_transition_cache.keys():
		var inner: Dictionary[int, int] = _remove_transition_cache[source_id]
		for component_id: int in inner.keys():
			if inner[component_id] == archetype_id:
				inner.erase(component_id)
		if inner.is_empty():
			_remove_transition_cache.erase(source_id)

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

func _is_normalized_component_ids(component_ids: PackedInt64Array) -> bool:
	if component_ids.is_empty():
		return true
	for i in range(1, component_ids.size()):
		if component_ids[i] <= component_ids[i - 1]:
			return false
	return true

func _ensure_normalized_component_ids(component_ids: PackedInt64Array) -> PackedInt64Array:
	if _is_normalized_component_ids(component_ids):
		return component_ids
	return _normalize_component_ids(component_ids)

func _find_cache_entry(hash_key: int, key: PackedInt64Array) -> _ArchetypeCacheEntry:
	if !_archetype_cache_buckets.has(hash_key):
		return null
	var bucket: Array = _archetype_cache_buckets[hash_key] as Array
	for entry in bucket:
		var cache_entry: _ArchetypeCacheEntry = entry as _ArchetypeCacheEntry
		if ECSArchetypeKey.equals(cache_entry.key, key):
			return cache_entry
	return null

func _insert_cache_entry(hash_key: int, entry: _ArchetypeCacheEntry) -> void:
	if !_archetype_cache_buckets.has(hash_key):
		_archetype_cache_buckets[hash_key] = []
	(_archetype_cache_buckets[hash_key] as Array).append(entry)

func _remove_archetype_cache_entry(key: PackedInt64Array) -> void:
	var hash_key: int = ECSArchetypeKey.hash_packed_ids(key)
	if !_archetype_cache_buckets.has(hash_key):
		return
	var bucket: Array = _archetype_cache_buckets[hash_key] as Array
	for i in range(bucket.size()):
		var cache_entry: _ArchetypeCacheEntry = bucket[i] as _ArchetypeCacheEntry
		if ECSArchetypeKey.equals(cache_entry.key, key):
			bucket.remove_at(i)
			break
	if bucket.is_empty():
		_archetype_cache_buckets.erase(hash_key)

func _build_archetype_info(key: PackedInt64Array) -> ECSArchetypeInfo:
	var max_component_id: int = 0
	for component_id in key:
		if component_id > max_component_id:
			max_component_id = component_id
	var bits: ECSBitMask = ECSBitMask.new(max_component_id + 1)
	for component_id in key:
		bits.bit_set(component_id, true)
	return ECSArchetypeInfo.new(bits, key)

func _append_archetype_to_registry(key: PackedInt64Array, info: ECSArchetypeInfo, cache_entry: _ArchetypeCacheEntry) -> int:
	var archetype_id: int = _archetype_registry.size()
	var archetype: ECSArchetype = ECSArchetype.new(info.bitmask._bits, key)
	_archetype_registry.append(archetype)
	_registered_archetypes.append(archetype)
	_archetype_id_to_key[archetype_id] = key
	cache_entry.archetype_id = archetype_id
	_archetypes_version += 1
	return archetype_id

## Один lookup: info + archetype id. normalized_ids должен быть sort+unique.
func _resolve_archetype_packed(normalized_ids: PackedInt64Array) -> int:
	if normalized_ids.is_empty():
		return -1
	var hash_key: int = ECSArchetypeKey.hash_packed_ids(normalized_ids)
	var existing: _ArchetypeCacheEntry = _find_cache_entry(hash_key, normalized_ids)
	if existing != null:
		if existing.archetype_id >= 0 && _get_archetype(existing.archetype_id) != null:
			return existing.archetype_id
		return _append_archetype_to_registry(existing.key, existing.info, existing)
	var key: PackedInt64Array = normalized_ids.duplicate()
	var info: ECSArchetypeInfo = _build_archetype_info(key)
	var entry: _ArchetypeCacheEntry = _ArchetypeCacheEntry.new()
	entry.key = key
	entry.info = info
	_insert_cache_entry(hash_key, entry)
	return _append_archetype_to_registry(key, info, entry)

## Transition path: bitmask уже построен, ids — нормализованный scratch (копируется).
func _resolve_archetype_from_bitmask(bits: ECSBitMask, normalized_ids: PackedInt64Array) -> int:
	if normalized_ids.is_empty():
		return -1
	var hash_key: int = ECSArchetypeKey.hash_packed_ids(normalized_ids)
	var existing: _ArchetypeCacheEntry = _find_cache_entry(hash_key, normalized_ids)
	if existing != null:
		if existing.archetype_id >= 0 && _get_archetype(existing.archetype_id) != null:
			return existing.archetype_id
		return _append_archetype_to_registry(existing.key, existing.info, existing)
	var key: PackedInt64Array = normalized_ids.duplicate()
	var info: ECSArchetypeInfo = ECSArchetypeInfo.new(bits, key)
	var entry: _ArchetypeCacheEntry = _ArchetypeCacheEntry.new()
	entry.key = key
	entry.info = info
	_insert_cache_entry(hash_key, entry)
	return _append_archetype_to_registry(key, info, entry)

func _packed_from_array(component_ids: Array[int]) -> PackedInt64Array:
	return PackedInt64Array(component_ids)

func _build_work_component_ids_after_add(old_archetype: ECSArchetype, component_id: int) -> void:
	var old_ids: PackedInt64Array = old_archetype._component_ids
	var old_size: int = old_ids.size()
	for i in range(old_size):
		if old_ids[i] == component_id:
			_work_component_ids = old_ids
			return
		if old_ids[i] > component_id:
			_work_component_ids.resize(old_size + 1)
			for j in range(i):
				_work_component_ids[j] = old_ids[j]
			_work_component_ids[i] = component_id
			for j in range(i, old_size):
				_work_component_ids[j + 1] = old_ids[j]
			return
	_work_component_ids.resize(old_size + 1)
	for j in range(old_size):
		_work_component_ids[j] = old_ids[j]
	_work_component_ids[old_size] = component_id

func _build_work_component_ids_after_remove(old_archetype: ECSArchetype, component_id: int) -> void:
	var old_ids: PackedInt64Array = old_archetype._component_ids
	var new_size: int = 0
	for c_id in old_ids:
		if c_id != component_id:
			new_size += 1
	_work_component_ids.resize(new_size)
	var write: int = 0
	for c_id in old_ids:
		if c_id != component_id:
			_work_component_ids[write] = c_id
			write += 1

func _prepare_work_bitmask_after_add(old_archetype: ECSArchetype, component_id: int) -> void:
	_work_bitmask.bit_copy_from(old_archetype.get_bitmask()._bits)
	_work_bitmask.bit_set(component_id, true)

func _prepare_work_bitmask_after_remove(old_archetype: ECSArchetype, component_id: int) -> void:
	_work_bitmask.bit_copy_from(old_archetype.get_bitmask()._bits)
	_work_bitmask.bit_set(component_id, false)

func _resolve_add_transition(old_archetype_id: int, component_id: int) -> int:
	if _add_transition_cache.has(old_archetype_id):
		var inner: Dictionary[int, int] = _add_transition_cache[old_archetype_id]
		if inner.has(component_id):
			return inner[component_id]
	var old_archetype: ECSArchetype = _get_archetype(old_archetype_id)
	if old_archetype == null:
		return old_archetype_id
	_build_work_component_ids_after_add(old_archetype, component_id)
	_prepare_work_bitmask_after_add(old_archetype, component_id)
	var new_archetype_id: int = _resolve_archetype_from_bitmask(_work_bitmask, _work_component_ids)
	if !_add_transition_cache.has(old_archetype_id):
		var fresh: Dictionary[int, int] = {}
		_add_transition_cache[old_archetype_id] = fresh
	var add_inner: Dictionary[int, int] = _add_transition_cache[old_archetype_id]
	add_inner[component_id] = new_archetype_id
	return new_archetype_id

func _resolve_remove_transition(old_archetype_id: int, component_id: int) -> int:
	if _remove_transition_cache.has(old_archetype_id):
		var inner: Dictionary[int, int] = _remove_transition_cache[old_archetype_id]
		if inner.has(component_id):
			return inner[component_id]
	var old_archetype: ECSArchetype = _get_archetype(old_archetype_id)
	if old_archetype == null:
		return old_archetype_id
	_build_work_component_ids_after_remove(old_archetype, component_id)
	if _work_component_ids.is_empty():
		return -1
	_prepare_work_bitmask_after_remove(old_archetype, component_id)
	var new_archetype_id: int = _resolve_archetype_from_bitmask(_work_bitmask, _work_component_ids)
	if !_remove_transition_cache.has(old_archetype_id):
		var fresh: Dictionary[int, int] = {}
		_remove_transition_cache[old_archetype_id] = fresh
	var remove_inner: Dictionary[int, int] = _remove_transition_cache[old_archetype_id]
	remove_inner[component_id] = new_archetype_id
	return new_archetype_id

func _entity_index(entity_id: int) -> int:
	return ECSEntityHandle.index_of(entity_id)

func _ensure_entity_mapping_capacity(entity_index: int) -> void:
	if entity_index >= _entities_to_archetypes.size():
		_entities_to_archetypes.resize(entity_index + 1)

func register_component(component_id: int, component_type: ECSComponent.Type) -> void:
	if _components.has(component_id):
		push_error("ECSManager: component %d already registered" % component_id)
		return
	if _tags.has(component_id):
		push_error("ECSManager: id %d already registered as tag" % component_id)
		return
	var component: ECSComponentBaseArray = ECSComponentFactory.create_component(component_type)
	if component == null:
		push_error("ECSManager: unknown component type for id %d" % component_id)
		return
	_components[component_id] = component

func register_tag(tag_id: int) -> void:
	if _tags.has(tag_id):
		push_error("ECSManager: tag %d already registered" % tag_id)
		return
	if _components.has(tag_id):
		push_error("ECSManager: id %d already registered as component" % tag_id)
		return
	_tags[tag_id] = true

func is_tag(component_id: int) -> bool:
	return _tags.has(component_id)

func _is_registered_id(component_id: int) -> bool:
	return _components.has(component_id) || _tags.has(component_id)

## Предрасчёт архетипа для набора компонентов (кэш + создание архетипа).
func precache_archetype_packed(component_ids: PackedInt64Array) -> void:
	var normalized_ids: PackedInt64Array = _ensure_normalized_component_ids(component_ids)
	if normalized_ids.is_empty():
		return
	_resolve_archetype_packed(normalized_ids)

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
	var normalized_ids: PackedInt64Array = _ensure_normalized_component_ids(component_ids)
	if normalized_ids.is_empty():
		push_error("ECSManager: empty component set in create_entity")
		return 0
	for component_id in normalized_ids:
		if !_is_registered_id(component_id):
			push_error("ECSManager: unregistered component %d in create_entity" % component_id)
			return 0
	var entity_id: int = _entity_ids_pool.get_next_entity_id()
	var archetype_id: int = _resolve_archetype_packed(normalized_ids)
	var archetype: ECSArchetype = _get_archetype(archetype_id)
	archetype.add_entity(entity_id)
	var entity_index: int = _entity_index(entity_id)
	_ensure_entity_mapping_capacity(entity_index)
	_entities_to_archetypes[entity_index] = archetype_id
	for component_id in archetype._component_ids:
		if is_tag(component_id):
			continue
		var component: ECSComponentBaseArray = _components[component_id]
		component.add_entity(entity_id)
	return entity_id

## Внешний API: Array[int], PackedInt64Array создаётся внутри.
func create_entity(component_ids: Array[int]) -> int:
	return create_entity_packed(_packed_from_array(component_ids))

func create_entities_packed(count: int, component_ids: PackedInt64Array) -> PackedInt64Array:
	if count <= 0:
		return PackedInt64Array()
	var normalized_ids: PackedInt64Array = _ensure_normalized_component_ids(component_ids)
	if normalized_ids.is_empty():
		push_error("ECSManager: empty component set in create_entities")
		return PackedInt64Array()
	for component_id in normalized_ids:
		if !_is_registered_id(component_id):
			push_error("ECSManager: unregistered component %d in create_entities" % component_id)
			return PackedInt64Array()
	var entity_ids: PackedInt64Array = PackedInt64Array()
	entity_ids.resize(count)
	var archetype_id: int = _resolve_archetype_packed(normalized_ids)
	var archetype: ECSArchetype = _get_archetype(archetype_id)
	for i in range(count):
		var entity_id: int = _entity_ids_pool.get_next_entity_id()
		entity_ids[i] = entity_id
		archetype.add_entity(entity_id)
		var entity_index: int = _entity_index(entity_id)
		_ensure_entity_mapping_capacity(entity_index)
		_entities_to_archetypes[entity_index] = archetype_id
	for component_id in archetype._component_ids:
		if is_tag(component_id):
			continue
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
	var archetype_chunk_removed: bool = false
	if archetype != null:
		archetype_chunk_removed = archetype.remove_entity(entity_id) >= 0
	var component_ids_to_clear: PackedInt64Array
	if archetype != null:
		component_ids_to_clear = archetype._component_ids
	else:
		component_ids_to_clear = PackedInt64Array(_components.keys())
	for component_id in component_ids_to_clear:
		if is_tag(component_id):
			continue
		var component: ECSComponentBaseArray = _components.get(component_id, null)
		if component != null:
			component.remove_entity(entity_id)
	_entity_ids_pool.free_entity_id(entity_id)
	_entities_to_archetypes[entity_index] = -1
	_note_archetype_gc_work(archetype_id, archetype_chunk_removed)

func destroy_entities_packed(entity_ids: PackedInt64Array) -> void:
	if entity_ids.is_empty():
		return
	_scratch_enter("destroy_entities_packed")
	_destroy_touched_ids.clear()
	var scratch_count: int = 0
	var first_archetype_id: int = -1
	var buckets_mode: bool = false
	_destroy_entity_scratch.resize(entity_ids.size())
	for entity_id in entity_ids:
		if !is_alive(entity_id):
			continue
		var entity_index: int = _entity_index(entity_id)
		if entity_index < 0 || entity_index >= _entities_to_archetypes.size():
			continue
		var archetype_id: int = _entities_to_archetypes[entity_index]
		if archetype_id < 0:
			continue
		if !buckets_mode:
			if first_archetype_id < 0:
				first_archetype_id = archetype_id
				_destroy_entity_scratch[scratch_count] = entity_id
				scratch_count += 1
			elif archetype_id == first_archetype_id:
				_destroy_entity_scratch[scratch_count] = entity_id
				scratch_count += 1
			else:
				buckets_mode = true
				_destroy_promote_scratch_to_bucket(first_archetype_id, scratch_count)
				scratch_count = 0
				_destroy_bucket_append(archetype_id, entity_id)
		else:
			_destroy_bucket_append(archetype_id, entity_id)
	if scratch_count == 0 && _destroy_touched_ids.is_empty():
		_scratch_leave()
		return
	if !buckets_mode:
		_destroy_entity_scratch.resize(scratch_count)
		_destroy_archetype_batch(first_archetype_id, _destroy_entity_scratch)
		_scratch_leave()
		return
	for archetype_id in _destroy_touched_ids:
		var batch: PackedInt64Array = _destroy_buckets[archetype_id]
		_destroy_archetype_batch(archetype_id, batch)
		batch.clear()
	_destroy_touched_ids.clear()
	_scratch_leave()

func _destroy_bucket_append(archetype_id: int, entity_id: int) -> void:
	if !_destroy_buckets.has(archetype_id):
		_destroy_buckets[archetype_id] = PackedInt64Array()
		_destroy_touched_ids.append(archetype_id)
	_destroy_buckets[archetype_id].append(entity_id)

func _destroy_promote_scratch_to_bucket(archetype_id: int, count: int) -> void:
	if count == 0:
		return
	if !_destroy_buckets.has(archetype_id):
		_destroy_buckets[archetype_id] = PackedInt64Array()
		_destroy_touched_ids.append(archetype_id)
	var bucket: PackedInt64Array = _destroy_buckets[archetype_id]
	for i in count:
		bucket.append(_destroy_entity_scratch[i])

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
	var archetype_chunk_removed: bool = archetype.remove_entities_batch(batch)
	for component_id in archetype._component_ids:
		if is_tag(component_id):
			continue
		var component: ECSComponentBaseArray = _components.get(component_id, null)
		if component != null:
			component.remove_entities_batch(batch)
	for entity_id in batch:
		_entity_ids_pool.free_entity_id(entity_id)
		_entities_to_archetypes[_entity_index(entity_id)] = -1
	_note_archetype_gc_work(archetype_id, archetype_chunk_removed)

func get_entity_archetype(entity_id: int) -> ECSArchetype:
	if !is_alive(entity_id):
		return null
	var entity_index: int = _entity_index(entity_id)
	if entity_index < 0 || entity_index >= _entities_to_archetypes.size():
		return null
	var archetype_id: int = _entities_to_archetypes[entity_index]
	return _get_archetype(archetype_id)

func get_registered_archetypes() -> Array[ECSArchetype]:
	return _registered_archetypes

func get_archetypes() -> Array[ECSArchetype]:
	return _registered_archetypes.duplicate()

func get_archetype_registry_size() -> int:
	return _archetype_registry.size()

func count_live_archetypes() -> int:
	var count: int = 0
	for archetype in _archetype_registry:
		if archetype != null && archetype.get_live_count() > 0:
			count += 1
	return count

func count_registered_archetypes() -> int:
	return _registered_archetypes.size()

func is_schema_registered() -> bool:
	return not _components.is_empty() or not _tags.is_empty()

func reset() -> void:
	var to_destroy: PackedInt64Array = PackedInt64Array()
	for archetype in _registered_archetypes:
		archetype.for_each_chunk_index(func(chunk_index: int) -> void:
			var chunk: ECSArchetypeChunk = archetype.get_archetype_chunk_by_index(chunk_index)
			if chunk == null:
				return
			var dense: PackedInt64Array = chunk.get_dense_entities()
			var entity_count: int = chunk.get_entity_count()
			for i in range(entity_count):
				to_destroy.append(dense[i])
		)
	if !to_destroy.is_empty():
		destroy_entities_packed(to_destroy)
	for component: ECSComponentBaseArray in _components.values():
		component.clear()
	_archetype_registry.clear()
	_registered_archetypes.clear()
	_archetype_id_to_key.clear()
	_archetype_cache_buckets.clear()
	_add_transition_cache.clear()
	_remove_transition_cache.clear()
	_entities_to_archetypes = PackedInt64Array()
	_entity_ids_pool = ECSEntityIdsPool.new()
	_pending_archetype_gc = false
	_gc_empty_archetype_candidates.clear()
	_gc_component_chunks_dirty = false
	_archetypes_version += 1

func gc_empty_archetypes() -> void:
	var to_evict: PackedInt32Array = PackedInt32Array()
	for archetype_id in range(_archetype_registry.size()):
		var archetype: ECSArchetype = _archetype_registry[archetype_id]
		if archetype != null && archetype.get_live_count() == 0:
			to_evict.append(archetype_id)
	for i in range(to_evict.size()):
		_evict_archetype(to_evict[i])

func has_component(entity_id: int, component_id: int) -> bool:
	if !is_alive(entity_id):
		return false
	var entity_index: int = _entity_index(entity_id)
	if entity_index < 0 || entity_index >= _entities_to_archetypes.size():
		return false
	var archetype_id: int = _entities_to_archetypes[entity_index]
	if archetype_id < 0:
		return false
	var archetype: ECSArchetype = _get_archetype(archetype_id)
	if archetype == null:
		return false
	return archetype.get_bitmask().bit_test(component_id)

func add_component(entity_id: int, component_id: int) -> void:
	if !is_alive(entity_id):
		return
	if has_component(entity_id, component_id):
		return
	if !_is_registered_id(component_id):
		push_error("ECSManager: unregistered component %d in add_component" % component_id)
		return
	var old_archetype: ECSArchetype = get_entity_archetype(entity_id)
	if old_archetype == null:
		return
	var entity_index: int = _entity_index(entity_id)
	var old_archetype_id: int = _entities_to_archetypes[entity_index]
	var new_archetype_id: int = _resolve_add_transition(old_archetype_id, component_id)
	var new_archetype: ECSArchetype = _get_archetype(new_archetype_id)
	var archetype_chunk_removed: bool = old_archetype.remove_entity(entity_id) >= 0
	new_archetype.add_entity(entity_id)
	_entities_to_archetypes[entity_index] = new_archetype_id
	if !is_tag(component_id):
		var component: ECSComponentBaseArray = _components[component_id]
		component.add_entity(entity_id)
	_note_archetype_gc_work(old_archetype_id, archetype_chunk_removed)

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
	var archetype_chunk_removed: bool = old_archetype.remove_entity(entity_id) >= 0
	new_archetype.add_entity(entity_id)
	_entities_to_archetypes[entity_index] = new_archetype_id
	if !is_tag(component_id):
		var component: ECSComponentBaseArray = _components[component_id]
		component.remove_entity(entity_id)
	_note_archetype_gc_work(old_archetype_id, archetype_chunk_removed)
