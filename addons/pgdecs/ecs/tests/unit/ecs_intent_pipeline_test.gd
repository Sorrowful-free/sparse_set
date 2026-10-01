extends GutTest

## Smoke-тест lazy-пути `examples/intent/`: spawn → bind → sync → release → destroy sweep.
## Проверяет главное свойство после отказа от slot-реестров:
## «есть нода» = членство в архетипе (компонент `NODE`), а не `slot >= 0`.

class _IntentHarness:
	var ecs: ECSManager
	var pool: ECSNodePool
	var runner: ECSSystemRunner

	func _init() -> void:
		ecs = ECSManager.new()
		ExampleIntentComponentRegistryStrategy.new().apply_to(ecs)

		pool = ECSNodePool.new()
		var dependencies: ExampleEcsDependencies = ExampleEcsDependencies.new()
		dependencies.node_pool = pool

		runner = ECSSystemRunner.new()
		runner.add_system(ExampleBindIntentSystem.new(ecs, dependencies), ECSSystemRunGroups.FRAME)
		runner.add_system(ExampleNodeSyncSystem.new(ecs, dependencies), ECSSystemRunGroups.FRAME)
		runner.add_system(ExampleReleaseIntentSystem.new(ecs, dependencies), ECSSystemRunGroups.FRAME)
		runner.add_system(ExampleDestroySweepSystem.new(ecs), ECSSystemRunGroups.FRAME)

	## Один кадр frame-группы (bind → sync → release → sweep).
	func tick() -> void:
		runner.run_group(ECSSystemRunGroups.FRAME, 0.0)

	## Spawn + запрос привязки; возвращает **реальный** entity id.
	func spawn_with_bind_request(position: Vector2) -> int:
		var buf: ECSCommandBuffer = ECSCommandBuffer.new(ecs)
		var temp_id: int = buf.create_entity([
			ExampleIntentComponentRegistryStrategy.Component.POSITION,
			ExampleIntentIds.INTENT_BIND_NODE,
		])
		buf.set_component(
			temp_id, ExampleIntentComponentRegistryStrategy.Component.POSITION, position
		)
		buf.execute()
		return _first_entity([ExampleIntentIds.INTENT_BIND_NODE])

	## Spawn без запроса привязки (ноды быть не должно).
	func spawn_plain(position: Vector2) -> int:
		var buf: ECSCommandBuffer = ECSCommandBuffer.new(ecs)
		var temp_id: int = buf.create_entity([ExampleIntentComponentRegistryStrategy.Component.POSITION])
		buf.set_component(
			temp_id, ExampleIntentComponentRegistryStrategy.Component.POSITION, position
		)
		buf.execute()
		return _first_entity([ExampleIntentComponentRegistryStrategy.Component.POSITION])

	func mark(entity_id: int, tag_id: int) -> void:
		var buf: ECSCommandBuffer = ECSCommandBuffer.new(ecs)
		buf.add_component(entity_id, tag_id)
		buf.execute()

	func node_of(entity_id: int) -> Node2D:
		var nodes: ECSComponentNode2DArray = ecs.get_component_array(
			ExampleIntentIds.NODE
		) as ECSComponentNode2DArray
		if nodes == null:
			return null
		return nodes.get_component(entity_id)

	## Отпустить всё, что осталось привязанным, и освободить пул —
	## чтобы тест не оставлял orphan-нод.
	func dispose() -> void:
		for entity_id: int in ECSQueryBuilder.new() \
				.with_component(ExampleIntentIds.NODE).build(ecs).get_entity_ids():
			mark(entity_id, ExampleIntentIds.INTENT_RELEASE)
		tick()
		pool.clear()

	func _first_entity(component_ids: Array[int]) -> int:
		var ids: PackedInt64Array = ECSQueryBuilder.new() \
			.with_components(component_ids).build(ecs).get_entity_ids()
		if ids.is_empty():
			return 0
		return ids[0]

func _make_node2d_scene() -> PackedScene:
	var root: Node2D = Node2D.new()
	var packed: PackedScene = PackedScene.new()
	packed.pack(root)
	root.free()
	return packed

func _harness() -> _IntentHarness:
	var harness: _IntentHarness = _IntentHarness.new()
	harness.pool.node_scene = _make_node2d_scene()
	return harness

func test_bind_adds_node_component_and_clears_intent() -> void:
	var h: _IntentHarness = _harness()
	var entity_id: int = h.spawn_with_bind_request(Vector2.ZERO)
	assert_ne(entity_id, 0)
	assert_false(h.ecs.has_component(entity_id, ExampleIntentIds.NODE), "до bind ноды нет")
	assert_true(h.ecs.has_component(entity_id, ExampleIntentIds.INTENT_BIND_NODE))

	h.tick()

	assert_true(h.ecs.has_component(entity_id, ExampleIntentIds.NODE), "bind добавил NODE")
	assert_false(
		h.ecs.has_component(entity_id, ExampleIntentIds.INTENT_BIND_NODE), "intent снят"
	)
	assert_not_null(h.node_of(entity_id))
	assert_eq(h.pool.available_count(), 0, "нода выдана сущности")
	h.dispose()

func test_sync_writes_position_into_bound_node() -> void:
	var h: _IntentHarness = _harness()
	var entity_id: int = h.spawn_with_bind_request(Vector2(3.0, 4.0))

	h.tick()

	var node: Node2D = h.node_of(entity_id)
	assert_not_null(node)
	assert_eq(node.global_position, Vector2(3.0, 4.0), "sync перенёс POSITION в ноду")
	h.dispose()

func test_unbound_entity_is_not_synced_and_pool_untouched() -> void:
	var h: _IntentHarness = _harness()
	var entity_id: int = h.spawn_plain(Vector2(9.0, 9.0))

	h.tick()

	assert_false(h.ecs.has_component(entity_id, ExampleIntentIds.NODE), "нода не появилась")
	assert_eq(h.pool.available_count(), 0, "пул не тронут")
	assert_true(h.ecs.is_alive(entity_id))
	h.dispose()

func test_release_returns_node_to_pool_and_removes_component() -> void:
	var h: _IntentHarness = _harness()
	var entity_id: int = h.spawn_with_bind_request(Vector2.ZERO)
	h.tick()
	assert_eq(h.pool.available_count(), 0)

	h.mark(entity_id, ExampleIntentIds.INTENT_RELEASE)
	h.tick()

	assert_false(h.ecs.has_component(entity_id, ExampleIntentIds.NODE), "release снял NODE")
	assert_false(h.ecs.has_component(entity_id, ExampleIntentIds.INTENT_RELEASE), "intent снят")
	assert_true(h.ecs.is_alive(entity_id), "до sweep сущность жива")
	assert_eq(h.pool.available_count(), 1, "нода вернулась в пул")
	h.dispose()

func test_destroy_sweep_removes_entity_after_release() -> void:
	var h: _IntentHarness = _harness()
	var entity_id: int = h.spawn_with_bind_request(Vector2.ZERO)
	h.tick()

	h.mark(entity_id, ExampleIntentIds.INTENT_RELEASE)
	h.mark(entity_id, ExampleIntentIds.INTENT_DESTROY)
	h.tick()

	assert_false(h.ecs.is_alive(entity_id), "sweep удалил сущность")
	assert_eq(h.pool.available_count(), 1, "нода освобождена до удаления")
	h.dispose()
