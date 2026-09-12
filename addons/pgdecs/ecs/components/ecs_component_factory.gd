extends RefCounted
class_name ECSComponentFactory

static func create_component(component_type: ECSComponent.Type) -> ECSComponentBaseArray:
	match component_type:
		ECSComponent.Type.PACKED_BYTE:
			return ECSComponentByteArray.new()
		ECSComponent.Type.PACKED_INT32:
			return ECSComponentInt32Array.new()
		ECSComponent.Type.PACKED_INT64:
			return ECSComponentInt64Array.new()
		ECSComponent.Type.PACKED_FLOAT32:
			return ECSComponentFloat32Array.new()
		ECSComponent.Type.PACKED_FLOAT64:
			return ECSComponentFloat64Array.new()
		ECSComponent.Type.PACKED_VECTOR2:
			return ECSComponentVector2Array.new()
		ECSComponent.Type.PACKED_VECTOR3:
			return ECSComponentVector3Array.new()
		ECSComponent.Type.PACKED_VECTOR4:
			return ECSComponentVector4Array.new()
		ECSComponent.Type.PACKED_COLOR:
			return ECSComponentColorArray.new()
		ECSComponent.Type.PACKED_STRING:
			return ECSComponentStringArray.new()
		ECSComponent.Type.AABB:
			return ECSComponentAABBArray.new()
		ECSComponent.Type.RECT2:
			return ECSComponentRect2Array.new()
		ECSComponent.Type.QUATERNION:
			return ECSComponentQuaternionArray.new()
		ECSComponent.Type.BASIS:
			return ECSComponentBasisArray.new()
		ECSComponent.Type.TRANSFORM2D:
			return ECSComponentTransform2DArray.new()
		ECSComponent.Type.TRANSFORM3D:
			return ECSComponentTransform3DArray.new()
		ECSComponent.Type.VECTOR2I:
			return ECSComponentVector2iArray.new()
		ECSComponent.Type.VECTOR3I:
			return ECSComponentVector3iArray.new()
		ECSComponent.Type.VECTOR4I:
			return ECSComponentVector4iArray.new()
		ECSComponent.Type.OBJECT:
			return ECSComponentObjectArray.new()
		ECSComponent.Type.NODE:
			return ECSComponentNodeArray.new()
		ECSComponent.Type.NODE2D:
			return ECSComponentNode2DArray.new()
		ECSComponent.Type.NODE3D:
			return ECSComponentNode3DArray.new()
		ECSComponent.Type.RESOURCE:
			return ECSComponentResourceArray.new()
		ECSComponent.Type.PACKED_SCENE:
			return ECSComponentPackedSceneArray.new()
		ECSComponent.Type.REF_COUNTED:
			return ECSComponentRefCountedArray.new()
		_:
			push_error("ECSComponentFactory: unsupported component type %d" % component_type)
			return null
