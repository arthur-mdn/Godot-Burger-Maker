extends Node3D

@export var order_manager: Node
@export var game_manager: Node

func place_item(item):
	if order_manager == null:
		return false

	var served_stack = item.stack.duplicate()
	item.queue_free()

	_process_serving(served_stack)
	return true

func _process_serving(served_stack) -> void:
	var success = await order_manager.validate_stack(served_stack)

	if game_manager != null:
		if success and game_manager.has_method("register_success"):
			game_manager.register_success()
		elif not success and game_manager.has_method("register_fail"):
			game_manager.register_fail()
