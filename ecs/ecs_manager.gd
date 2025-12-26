extends Node

class_name EcsManager

@export var chunk_capacity: int = 1024
@export var component_capacity: int = chunk_capacity * 8

var _entity_ids_pool: EntityIdsPool = EntityIdsPool.new()

var _components: Dictionary[int, ComponentBase] = {}
var _archetypes: Dictionary[int, Archetype] = {}
var _entities_to_archetypes: PackedInt64Array = PackedInt64Array()

func _init() -> void:
	pass

func register_component(component_id: int, component_type: Variant.Type) -> void:
	if _components.has(component_id):
		return
	var component: ComponentBase = ComponentFactory.create_component(component_type, component_capacity, chunk_capacity)
	if component == null:
		return
	_components[component_id] = component


func create_entity(...component_ids: Array) -> int:
	var entity_id: int = _entity_ids_pool.get_next_entity_id()
	
	var packed_component_ids: PackedInt64Array = PackedInt64Array(component_ids)
	
	# Создаем битовую маску для компонентов
	var max_component_id: int = 0
	for component_id in component_ids:
		if component_id > max_component_id:
			max_component_id = component_id
	
	var component_ids_bits: BitMask = BitMask.new(max_component_id + 1)
	for component_id in component_ids:
		component_ids_bits.bit_set(component_id, true)
	
	# Находим или создаем архетип
	var archetype_hash: int = component_ids_bits.bit_hash()

	
	var archetype: Archetype

	if !_archetypes.has(archetype_hash):
		_archetypes[archetype_hash] = Archetype.new(component_ids_bits._bits, packed_component_ids, chunk_capacity)
	
	archetype = _archetypes[archetype_hash]
	archetype.add_entity(entity_id)
	
	# Сохраняем связь entity_id -> archetype_hash
	if entity_id >= _entities_to_archetypes.size():
		_entities_to_archetypes.resize(entity_id + 1)
	_entities_to_archetypes[entity_id] = archetype_hash
	
	# Добавляем сущность в компоненты
	for component_id in component_ids:
		var component: ComponentBase = _components[component_id]
		if component != null:
			component.add_entity(entity_id)

	return entity_id

func destroy_entity(entity_id: int) -> void:
	if entity_id < 0 || entity_id >= _entities_to_archetypes.size():
		return
	
	var archetype_hash: int = _entities_to_archetypes[entity_id]
	if _archetypes.has(archetype_hash):
		var archetype: Archetype = _archetypes[archetype_hash]
		archetype.remove_entity(entity_id)
	
	# Удаляем сущность из всех компонентов
	for component_id in _components.keys():
		var component: ComponentBase = _components[component_id]
		if component != null && component.has_entity(entity_id):
			component.remove_entity(entity_id)
	
	_entity_ids_pool.free_entity_id(entity_id)
	
	if entity_id < _entities_to_archetypes.size():
		_entities_to_archetypes[entity_id] = -1

func get_entity_archetype(entity_id: int) -> Archetype:
	if entity_id < 0 || entity_id >= _entities_to_archetypes.size():
		return null
	var archetype_hash: int = _entities_to_archetypes[entity_id]
	if _archetypes.has(archetype_hash):
		return _archetypes[archetype_hash]
	return null

func has_component(entity_id: int, component_id: int) -> bool:
	if !_components.has(component_id):
		return false
	var component: ComponentBase = _components[component_id]
	return component.has_entity(entity_id)
