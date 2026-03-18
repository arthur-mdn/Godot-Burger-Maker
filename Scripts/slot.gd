extends Node3D

var current_item = null

func can_place():
	return current_item == null

func place_item(item):
	if current_item == null:
		current_item = item
		item.current_slot = self
		item.global_position = global_position + Vector3(0, 0.5, 0)
	else:
		if current_item.can_merge(item):
			current_item.merge(item)
		else:
			print("INVALID MERGE")

func remove_item():
	if current_item:
		current_item.current_slot = null

	var item = current_item
	current_item = null
	return item
