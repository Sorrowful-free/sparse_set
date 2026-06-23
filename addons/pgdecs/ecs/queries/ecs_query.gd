class_name ECSQuery extends RefCounted

var _components_bitmask: ECSBitMask
var _without_components_bitmask: ECSBitMask

var _component_ids: PackedInt64Array
var _without_component_ids: PackedInt64Array

var _ecs_manager: ECSManager
var _cached_archetypes: Array[ECSArchetype] = []
var _cached_archetypes_version: int = -1
var _cached_chunks: Array[ECSQueryChunk] = []

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

func get_entity_ids() -> PackedInt64Array:
	var result: PackedInt64Array = PackedInt64Array()
	for chunk in get_chunks():
		var ids: PackedInt64Array = chunk.get_entity_ids()
		for i in range(ids.size()):
			if ids[i] >= 0:
				result.append(ids[i])
	return result

func _ensure_archetype_cache() -> void:
	var version: int = _ecs_manager.get_archetypes_version()
	if _cached_archetypes_version == version:
		return
	_cached_archetypes_version = version
	_cached_archetypes.clear()
	for archetype in _ecs_manager.get_archetypes():
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

func get_chunks() -> Array[ECSQueryChunk]:
	_ensure_archetype_cache()
	_cached_chunks.clear()
	for archetype in _cached_archetypes:
		var entity_chunks: Array[PackedInt64Array] = archetype.get_chunks()
		for chunk_index in range(entity_chunks.size()):
			var entity_ids_chunk: PackedInt64Array = entity_chunks[chunk_index]
			if entity_ids_chunk.is_empty():
				continue
			_cached_chunks.append(ECSQueryChunk.new(entity_ids_chunk, _ecs_manager, chunk_index))
	return _cached_chunks
