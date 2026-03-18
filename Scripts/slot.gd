extends Node3D

var current_item = null

func can_place() -> bool:
	return current_item == null

func place_item(item) -> bool:
	if current_item == null:
		current_item = item
		item.current_slot = self
		item.global_position = global_position + Vector3(0, 0.5, 0)
		return true
	else:
		if current_item.can_merge(item):
			current_item.merge(item)
			return true
		else:
			print("MERGE INVALIDE")
			return false

func remove_item():
	if current_item:
		current_item.current_slot = null
	var item = current_item
	current_item = null
	return item
