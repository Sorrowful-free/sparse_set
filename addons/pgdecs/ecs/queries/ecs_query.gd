class_name ECSQuery extends RefCounted

var _components_bitmask: ECSBitMask
var _without_components_bitmask: ECSBitMask

var _component_ids: PackedInt64Array
var _without_component_ids: PackedInt64Array

var _ecs_manager: ECSManager
var _cached_archetypes: Array[ECSArchetype] = []
var _cached_archetypes_version: int = -1
var _chunk_pool: Array[ECSQueryChunk] = []
var _chunk_pool_used: int = 0

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
	var mask_capacity: int = maxi(1, max_component_id + 1)
	_components_bitmask = ECSBitMask.new(mask_capacity)
	_without_components_bitmask = ECSBitMask.new(mask_capacity)
	for component_id in component_ids:
		_components_bitmask.bit_set(component_id, true)
	for component_id in without_component_ids:
		_without_components_bitmask.bit_set(component_id, true)

func match(entity_id: int) -> bool:
	if !_ecs_manager.is_alive(entity_id):
		return false
	for component_id in _component_ids:
		if !_ecs_manager.has_component(entity_id, component_id):
			return false
	for component_id in _without_component_ids:
		if _ecs_manager.has_component(entity_id, component_id):
			return false
	return true

func get_component_ids() -> PackedInt64Array:
	return _component_ids

func get_entity_ids() -> PackedInt64Array:
	var result: PackedInt64Array = PackedInt64Array()
	var run_count: int = begin_chunk_run()
	for i in range(run_count):
		var chunk: ECSQueryChunk = get_chunk_at_run_index(i)
		var dense: PackedInt64Array = chunk.get_dense_entities()
		var count: int = chunk.get_entity_count()
		for j in range(count):
			result.append(dense[j])
	return result

## Заполняет внутренний пул chunk-views и возвращает число чанков. Views инвалидируются следующим begin_chunk_run / for_each_chunk.
func begin_chunk_run() -> int:
	_ensure_archetype_cache()
	_chunk_pool_used = 0
	for archetype in _cached_archetypes:
		var chunk_indices: PackedInt32Array = archetype.get_dense_chunk_indices()
		for i in range(chunk_indices.size()):
			var chunk_index: int = chunk_indices[i]
			var archetype_chunk: ECSArchetypeChunk = archetype.get_archetype_chunk_by_index(chunk_index)
			if archetype_chunk.get_entity_count() == 0:
				continue
			_acquire_query_chunk(archetype_chunk, chunk_index)
	return _chunk_pool_used

## Чанк текущего run по индексу [0, begin_chunk_run()). Не сохранять между вызовами begin_chunk_run.
func get_chunk_at_run_index(index: int) -> ECSQueryChunk:
	return _chunk_pool[index]

## Итерация по чанкам без возврата Array вызывающему коду (alloc-free hot path).
## Объекты ECSQueryChunk переиспользуются из внутреннего пула — не сохранять между вызовами.
func for_each_chunk(callback: Callable) -> void:
	var run_count: int = begin_chunk_run()
	for i in range(run_count):
		callback.call(_chunk_pool[i])

func _ensure_archetype_cache() -> void:
	var version: int = _ecs_manager.get_archetypes_version()
	if _cached_archetypes_version == version:
		return
	_cached_archetypes_version = version
	_cached_archetypes.clear()
	for archetype in _ecs_manager.get_registered_archetypes():
		var arch_mask: ECSBitMask = archetype.get_bitmask()
		if !arch_mask.bit_match(_components_bitmask):
			continue
		var has_forbidden: bool = false
		for without_id in _without_component_ids:
			if arch_mask.bit_test(without_id):
				has_forbidden = true
				break
		if has_forbidden:
			continue
		_cached_archetypes.append(archetype)

func _acquire_query_chunk(archetype_chunk: ECSArchetypeChunk, chunk_index: int) -> ECSQueryChunk:
	if _chunk_pool_used < _chunk_pool.size():
		var pooled: ECSQueryChunk = _chunk_pool[_chunk_pool_used]
		_chunk_pool_used += 1
		pooled.reset(archetype_chunk, _ecs_manager, chunk_index)
		return pooled
	var query_chunk: ECSQueryChunk = ECSQueryChunk.new(archetype_chunk, _ecs_manager, chunk_index)
	_chunk_pool.append(query_chunk)
	_chunk_pool_used += 1
	return query_chunk

func _create_snapshot_chunk(archetype_chunk: ECSArchetypeChunk, chunk_index: int) -> ECSQueryChunk:
	return ECSQueryChunk.new(archetype_chunk, _ecs_manager, chunk_index)

## Заполняет out_chunks views на текущий run. По умолчанию reuse_snapshot=true — ссылки на pooled views (как begin_chunk_run).
func collect_chunks(out_chunks: Array[ECSQueryChunk], reuse_snapshot: bool = true) -> void:
	out_chunks.clear()
	if reuse_snapshot:
		var run_count: int = begin_chunk_run()
		for i in range(run_count):
			out_chunks.append(_chunk_pool[i])
		return
	_ensure_archetype_cache()
	for archetype in _cached_archetypes:
		var chunk_indices: PackedInt32Array = archetype.get_dense_chunk_indices()
		for i in range(chunk_indices.size()):
			var chunk_index: int = chunk_indices[i]
			var archetype_chunk: ECSArchetypeChunk = archetype.get_archetype_chunk_by_index(chunk_index)
			if archetype_chunk.get_entity_count() == 0:
				continue
			out_chunks.append(_create_snapshot_chunk(archetype_chunk, chunk_index))

## Заполняет out_active instance_id archetype-чанков, видимых query (для change_detection prune).
func collect_active_chunk_instance_ids(out_active: Dictionary[int, bool]) -> void:
	out_active.clear()
	_ensure_archetype_cache()
	for archetype in _cached_archetypes:
		var chunk_indices: PackedInt32Array = archetype.get_dense_chunk_indices()
		for i in range(chunk_indices.size()):
			var chunk_index: int = chunk_indices[i]
			var archetype_chunk: ECSArchetypeChunk = archetype.get_archetype_chunk_by_index(chunk_index)
			if archetype_chunk.get_entity_count() == 0:
				continue
			out_active[archetype_chunk.get_instance_id()] = true

## Возвращает ссылки на pooled chunk views текущего run; не сохранять между вызовами get_chunks / begin_chunk_run.
func get_chunks() -> Array[ECSQueryChunk]:
	var result: Array[ECSQueryChunk] = []
	collect_chunks(result)
	return result

func get_chunk_pool_size() -> int:
	return _chunk_pool.size()
