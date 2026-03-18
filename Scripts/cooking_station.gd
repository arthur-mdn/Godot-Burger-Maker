extends Node3D

var current_item = null

func place_item(item):
	if current_item != null:
		return

	if item.type != item.ItemType.STEAK:
		print("PAS UN STEAK")
		return

	current_item = item
	item.current_slot = self
	item.global_position = global_position + Vector3(0, 0.5, 0)

	start_cooking(item)

func start_cooking(item):
	item.cooking_id += 1
	var id = item.cooking_id

	item.cook_state = item.CookState.COOKING
	item.rebuild_visual()
	print("COOKING...")

	await get_tree().create_timer(5).timeout

	if id != item.cooking_id:
		return

	if item.current_slot != self:
		return

	item.cook_state = item.CookState.COOKED
	item.rebuild_visual()
	print("CUIT")

	await get_tree().create_timer(3).timeout

	if id != item.cooking_id:
		return

	if item.current_slot != self:
		return

	item.cook_state = item.CookState.BURNT
	item.rebuild_visual()
	print("BRULÉ")

func remove_item():
	if current_item:
		current_item.cooking_id += 1

		if current_item.cook_state == current_item.CookState.COOKING:
			current_item.cook_state = current_item.CookState.RAW
			current_item.rebuild_visual()

	var item = current_item
	current_item = null
	return item
