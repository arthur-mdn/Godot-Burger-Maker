extends Node3D

func place_item(item) -> bool:
	if item.current_slot != null:
		item.current_slot.remove_item()
	item.queue_free()
	print("🗑️ Supprimé : ", item.name)
	return true

func remove_item():
	return null
