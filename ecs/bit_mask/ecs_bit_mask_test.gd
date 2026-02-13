@tool
extends EditorScript
class_name bit_mask_test

func _run():
	var bit_mask: ECSBitMask = ECSBitMask.new(3)
	bit_mask.bit_set(0, true)
	bit_mask.bit_set(1, true)
	bit_mask.bit_set(2, true)

	print("initial state")
	print(bit_mask._bits)

	print(bit_mask.bit_test(0))
	print(bit_mask.bit_test(1))
	print(bit_mask.bit_test(2))

	var bit_mask_2: ECSBitMask = ECSBitMask.new(3)
	
	print("initial hash")
	print(hash(bit_mask))
	print(hash(bit_mask_2))
	
	bit_mask_2.bit_set(0, true)
	bit_mask_2.bit_set(1, true)
	bit_mask_2.bit_set(2, true)
	
	print("same bitset hash")
	print(hash(bit_mask))
	print(hash(bit_mask_2))

	print(hash(bit_mask._bits))
	print(hash(bit_mask_2._bits))
	
	print("different bitset hash")
	bit_mask_2.bit_set(3, true)
	print(hash(bit_mask._bits))
	print(hash(bit_mask_2._bits))
	
	print("clear bitset hash")
	bit_mask_2.bit_set(3, false)
	print(hash(bit_mask._bits))
	print(hash(bit_mask_2._bits))
