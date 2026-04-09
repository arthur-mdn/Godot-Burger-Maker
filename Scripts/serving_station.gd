extends Node3D

@export var order_manager: Node
@export var game_manager: Node

func place_item(item):
	if order_manager == null:
		return false

	item.queue_free()

	_process_serving(item)
	return true

func _process_serving(item) -> void:
	var success = await order_manager.validate(item)

	if game_manager != null:
		if success and game_manager.has_method("register_success"):
			game_manager.register_success()
		elif not success and game_manager.has_method("register_fail"):
			game_manager.register_fail()
