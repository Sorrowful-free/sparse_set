extends RefCounted
class_name EntityIdsUtilsTest

func test_chunk_index_zero(runner: ECSTestRunner) -> void:
	runner.assert_eq(EntityIdsUtils.get_chunk_index(0), 0)
	runner.assert_eq(EntityIdsUtils.get_chunk_entity_index(0), 0)

func test_chunk_index_within_first_chunk(runner: ECSTestRunner) -> void:
	runner.assert_eq(EntityIdsUtils.get_chunk_index(255), 0)
	runner.assert_eq(EntityIdsUtils.get_chunk_entity_index(255), 255)

func test_chunk_index_second_chunk(runner: ECSTestRunner) -> void:
	runner.assert_eq(EntityIdsUtils.get_chunk_index(256), 1)
	runner.assert_eq(EntityIdsUtils.get_chunk_entity_index(256), 0)

func test_chunk_index_roundtrip(runner: ECSTestRunner) -> void:
	for entity_id in [0, 1, 255, 256, 257, 512, 1000]:
		var ci: int = EntityIdsUtils.get_chunk_index(entity_id)
		var ei: int = EntityIdsUtils.get_chunk_entity_index(entity_id)
		runner.assert_eq(ci * EntityIdsUtils.CHUNK_SIZE + ei, entity_id)
