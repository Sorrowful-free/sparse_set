extends RefCounted
class_name ECSComponentFactory

static func create_component(component_type: ECSComponent.Type) -> ECSComponentBaseArray:
	match component_type:
		ECSComponent.Type.PACKED_BYTE:
			return ECSComponentPackedByteArray.new()
		ECSComponent.Type.PACKED_INT64:
			return ECSComponentPackedInt64Array.new()
		ECSComponent.Type.PACKED_INT32:
			return ECSComponentPackedInt32Array.new()
		ECSComponent.Type.PACKED_FLOAT64:
			return ECSComponentPackedFloat64Array.new()
		ECSComponent.Type.PACKED_FLOAT32:
			return ECSComponentPackedFloat32Array.new()
		ECSComponent.Type.PACKED_VECTOR2:
			return ECSComponentPackedVector2Array.new()
		ECSComponent.Type.PACKED_VECTOR3:
			return ECSComponentPackedVector3Array.new()
		ECSComponent.Type.PACKED_VECTOR4:
			return ECSComponentPackedVector4Array.new()
		ECSComponent.Type.PACKED_COLOR:
			return ECSComponentPackedColorArray.new()
		ECSComponent.Type.PACKED_STRING:
			return ECSComponentPackedStringArray.new()
		ECSComponent.Type.BOOL:
			return ECSComponentBoolArray.new()
		ECSComponent.Type.INT:
			return ECSComponentIntArray.new()
		ECSComponent.Type.FLOAT:
			return ECSComponentFloatArray.new()
		ECSComponent.Type.AABB:
			return ECSComponentAABBArray.new()
		ECSComponent.Type.RECT2:
			return ECSComponentRect2Array.new()
		ECSComponent.Type.BASIS:
			return ECSComponentBasisArray.new()
		ECSComponent.Type.PLANE:
			return ECSComponentPlaneArray.new()
		ECSComponent.Type.TRANSFORM2D:
			return ECSComponentTransform2DArray.new()
		ECSComponent.Type.TRANSFORM3D:
			return ECSComponentTransform3DArray.new()
		ECSComponent.Type.QUATERNION:
			return ECSComponentQuaternionArray.new()
		ECSComponent.Type.VECTOR2:
			return ECSComponentVector2Array.new()
		ECSComponent.Type.VECTOR2I:
			return ECSComponentVector2iArray.new()
		ECSComponent.Type.VECTOR3I:
			return ECSComponentVector3iArray.new()
		ECSComponent.Type.VECTOR3:
			return ECSComponentVector3Array.new()
		ECSComponent.Type.VECTOR4I:
			return ECSComponentVector4iArray.new()
		ECSComponent.Type.VECTOR4:
			return ECSComponentVector4Array.new()
		ECSComponent.Type.COLOR:
			return ECSComponentColorArray.new()
		ECSComponent.Type.STRINGNAME:
			return ECSComponentStringNameArray.new()
		ECSComponent.Type.STRING:
			return ECSComponentStringArray.new()
		ECSComponent.Type.NODEPATH:
			return ECSComponentNodePathArray.new()
		ECSComponent.Type.RID:
			return ECSComponentRIDArray.new()
		ECSComponent.Type.RESOURCE:
			return ECSComponentResourceArray.new()
		ECSComponent.Type.PACKED_SCENE:
			return ECSComponentPackedSceneArray.new()
		ECSComponent.Type.NODE:
			return ECSComponentNodeArray.new()
		ECSComponent.Type.NODE2D:
			return ECSComponentNode2DArray.new()
		ECSComponent.Type.NODE3D:
			return ECSComponentNode3DArray.new()
		ECSComponent.Type.OBJECT:
			return ECSComponentObjectArray.new()
		ECSComponent.Type.REFCOUNTED:
			return ECSComponentRefCountedArray.new()
		_:
			push_error("ECSComponentFactory: unsupported component type %d" % component_type)
			return null
