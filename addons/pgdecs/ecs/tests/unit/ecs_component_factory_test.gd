extends GutTest
class_name ECSComponentFactoryTest

## Все значения ECSComponent.Type — фабрика должна создавать для каждого непустой storage.
const ALL_TYPES: Array[int] = [
	ECSComponent.Type.PACKED_BYTE,
	ECSComponent.Type.PACKED_INT64,
	ECSComponent.Type.PACKED_INT32,
	ECSComponent.Type.PACKED_FLOAT64,
	ECSComponent.Type.PACKED_FLOAT32,
	ECSComponent.Type.PACKED_STRING,
	ECSComponent.Type.PACKED_COLOR,
	ECSComponent.Type.PACKED_VECTOR2,
	ECSComponent.Type.PACKED_VECTOR3,
	ECSComponent.Type.PACKED_VECTOR4,
	ECSComponent.Type.BOOL,
	ECSComponent.Type.INT,
	ECSComponent.Type.FLOAT,
	ECSComponent.Type.AABB,
	ECSComponent.Type.RECT2,
	ECSComponent.Type.RECT2I,
	ECSComponent.Type.BASIS,
	ECSComponent.Type.PLANE,
	ECSComponent.Type.PROJECTION,
	ECSComponent.Type.TRANSFORM2D,
	ECSComponent.Type.TRANSFORM3D,
	ECSComponent.Type.QUATERNION,
	ECSComponent.Type.VECTOR2,
	ECSComponent.Type.VECTOR2I,
	ECSComponent.Type.VECTOR3,
	ECSComponent.Type.VECTOR3I,
	ECSComponent.Type.VECTOR4,
	ECSComponent.Type.VECTOR4I,
	ECSComponent.Type.COLOR,
	ECSComponent.Type.STRINGNAME,
	ECSComponent.Type.STRING,
	ECSComponent.Type.NODEPATH,
	ECSComponent.Type.RID,
	ECSComponent.Type.RESOURCE,
	ECSComponent.Type.PACKED_SCENE,
	ECSComponent.Type.NODE,
	ECSComponent.Type.NODE2D,
	ECSComponent.Type.NODE3D,
	ECSComponent.Type.OBJECT,
	ECSComponent.Type.REFCOUNTED,
	ECSComponent.Type.TWEEN,
	ECSComponent.Type.ANIMATION_PLAYER,
	ECSComponent.Type.ANIMATION_TREE,
	ECSComponent.Type.MESH_INSTANCE_2D,
	ECSComponent.Type.MESH_INSTANCE_3D,
	ECSComponent.Type.MULTI_MESH_INSTANCE_2D,
	ECSComponent.Type.MULTI_MESH_INSTANCE_3D,
	ECSComponent.Type.RIGID_BODY_2D,
	ECSComponent.Type.RIGID_BODY_3D,
	ECSComponent.Type.CHARACTER_BODY_2D,
	ECSComponent.Type.CHARACTER_BODY_3D,
	ECSComponent.Type.STATIC_BODY_2D,
	ECSComponent.Type.STATIC_BODY_3D,
	ECSComponent.Type.AREA_2D,
	ECSComponent.Type.AREA_3D,
	ECSComponent.Type.COLLISION_SHAPE_2D,
	ECSComponent.Type.COLLISION_SHAPE_3D,
	ECSComponent.Type.COLLISION_POLYGON_2D,
	ECSComponent.Type.COLLISION_POLYGON_3D,
	ECSComponent.Type.SHAPE_2D,
	ECSComponent.Type.SHAPE_3D,
	ECSComponent.Type.NAVIGATION_AGENT_2D,
	ECSComponent.Type.NAVIGATION_AGENT_3D,
	ECSComponent.Type.TIMER,
]

func test_known_types() -> void:
	for t: int in ALL_TYPES:
		assert_not_null(
			ECSComponentFactory.create_component(t as ECSComponent.Type),
			"create_component должен вернуть storage для типа %d" % t
		)

func test_storage_classes() -> void:
	assert_true(ECSComponentFactory.create_component(ECSComponent.Type.PACKED_VECTOR2) is ECSComponentPackedVector2Array)
	assert_true(ECSComponentFactory.create_component(ECSComponent.Type.PACKED_STRING) is ECSComponentPackedStringArray)
	assert_true(ECSComponentFactory.create_component(ECSComponent.Type.AABB) is ECSComponentAABBArray)
	assert_true(ECSComponentFactory.create_component(ECSComponent.Type.RECT2I) is ECSComponentRect2iArray)
	assert_true(ECSComponentFactory.create_component(ECSComponent.Type.PLANE) is ECSComponentPlaneArray)
	assert_true(ECSComponentFactory.create_component(ECSComponent.Type.PROJECTION) is ECSComponentProjectionArray)
	assert_true(ECSComponentFactory.create_component(ECSComponent.Type.VECTOR2) is ECSComponentVector2Array)
	assert_true(ECSComponentFactory.create_component(ECSComponent.Type.COLOR) is ECSComponentColorArray)
	assert_true(ECSComponentFactory.create_component(ECSComponent.Type.STRING) is ECSComponentStringArray)
	assert_true(ECSComponentFactory.create_component(ECSComponent.Type.STRINGNAME) is ECSComponentStringNameArray)
	assert_true(ECSComponentFactory.create_component(ECSComponent.Type.NODEPATH) is ECSComponentNodePathArray)
	assert_true(ECSComponentFactory.create_component(ECSComponent.Type.RID) is ECSComponentRIDArray)
	assert_true(ECSComponentFactory.create_component(ECSComponent.Type.OBJECT) is ECSComponentObjectArray)
	assert_true(ECSComponentFactory.create_component(ECSComponent.Type.NODE2D) is ECSComponentNode2DArray)
	assert_true(ECSComponentFactory.create_component(ECSComponent.Type.RESOURCE) is ECSComponentResourceArray)
	assert_true(ECSComponentFactory.create_component(ECSComponent.Type.TWEEN) is ECSComponentTweenArray)
	assert_true(ECSComponentFactory.create_component(ECSComponent.Type.ANIMATION_PLAYER) is ECSComponentAnimationPlayerArray)
	assert_true(ECSComponentFactory.create_component(ECSComponent.Type.MULTI_MESH_INSTANCE_3D) is ECSComponentMultiMeshInstance3DArray)
	assert_true(ECSComponentFactory.create_component(ECSComponent.Type.CHARACTER_BODY_3D) is ECSComponentCharacterBody3DArray)
	assert_true(ECSComponentFactory.create_component(ECSComponent.Type.AREA_3D) is ECSComponentArea3DArray)
	assert_true(ECSComponentFactory.create_component(ECSComponent.Type.COLLISION_SHAPE_3D) is ECSComponentCollisionShape3DArray)
	assert_true(ECSComponentFactory.create_component(ECSComponent.Type.STATIC_BODY_3D) is ECSComponentStaticBody3DArray)
	assert_true(ECSComponentFactory.create_component(ECSComponent.Type.SHAPE_3D) is ECSComponentShape3DArray)
	assert_true(ECSComponentFactory.create_component(ECSComponent.Type.NAVIGATION_AGENT_3D) is ECSComponentNavigationAgent3DArray)
	assert_true(ECSComponentFactory.create_component(ECSComponent.Type.TIMER) is ECSComponentTimerArray)

func test_invalid_type_returns_null() -> void:
	assert_null(ECSComponentFactory.create_component(999 as ECSComponent.Type))
	assert_push_error("unsupported component type")
