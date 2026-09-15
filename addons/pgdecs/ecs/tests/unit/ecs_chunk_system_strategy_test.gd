extends GutTest
class_name ECSChunkSystemStrategyTest

class _MockChunkSystem extends ECSSystemChunkBase:
	func build_query() -> ECSQuery:
		return null

	func process_chunk(_chunk: ECSQueryChunk, _delta: float) -> void:
		pass

class _MockChunkStrategy extends ECSChunkSystemStrategy:
	func create_system(ecs: ECSManager, _world: ECSWorld = null) -> ECSSystemBase:
		var system: _MockChunkSystem = _MockChunkSystem.new(ecs)
		_apply_chunk_system_settings(system)
		return system

func test_strategy_applies_parallel_settings() -> void:
	var settings: ECSChunkParallelSettings = ECSChunkParallelSettings.new()
	settings.chunks_per_task = 4
	settings.min_parallel_tasks = 3
	settings.parallel_mode = ECSChunkParallelSettings.ParallelMode.FORCE
	var strategy: _MockChunkStrategy = _MockChunkStrategy.new()
	strategy.use_worker_pool = true
	strategy.change_detection = true
	strategy.parallel_settings = settings
	var system: _MockChunkSystem = strategy.create_system(ECSManager.new()) as _MockChunkSystem
	assert_not_null(system)
	assert_true(system.use_worker_pool)
	assert_true(system.change_detection)
	assert_eq(system.parallel_settings.chunks_per_task, 4)
	assert_eq(system.parallel_settings.min_parallel_tasks, 3)
	assert_eq(system.parallel_settings.parallel_mode, ECSChunkParallelSettings.ParallelMode.FORCE)
