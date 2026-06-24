extends GutTest
class_name ECSEntityIdsUtilsTest

func test_chunk_index_zero() -> void:
	assert_eq(ECSEntityIdsUtils.get_chunk_index(0), 0)
	assert_eq(ECSEntityIdsUtils.get_chunk_entity_index(0), 0)

func test_chunk_index_within_first_chunk() -> void:
	assert_eq(ECSEntityIdsUtils.get_chunk_index(255), 0)
	assert_eq(ECSEntityIdsUtils.get_chunk_entity_index(255), 255)

func test_chunk_index_second_chunk() -> void:
	assert_eq(ECSEntityIdsUtils.get_chunk_index(256), 1)
	assert_eq(ECSEntityIdsUtils.get_chunk_entity_index(256), 0)

func test_chunk_index_roundtrip() -> void:
	for entity_id in [0, 1, 255, 256, 257, 512, 1000]:
		var ci: int = ECSEntityIdsUtils.get_chunk_index(entity_id)
		var ei: int = ECSEntityIdsUtils.get_chunk_entity_index(entity_id)
		assert_eq(ci * ECSEntityIdsUtils.CHUNK_SIZE + ei, entity_id)
