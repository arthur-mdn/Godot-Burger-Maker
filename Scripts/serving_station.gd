extends Node3D

@export var order_manager: Node

func place_item(item):
	if order_manager == null:
		return

	order_manager.validate(item)

	item.queue_free()
