extends Node

signal order_expired

const OrderCardScene := preload("res://Scenes/OrderCard.tscn")

const INGREDIENT_NAMES := ["Pain", "Steak", "Fromage", "Tomate", "Salade", "Oignon"]

var orders = []
var available_orders = []
var _next_order_number := 1
@export var orders_container: VBoxContainer

const MAX_ORDERS := 3
const ORDER_TIME := 40.0

func _ready():
	print("OrderManager OK")

func set_level_orders(new_orders):
	available_orders = new_orders.duplicate(true)

func clear_orders():
	orders.clear()
	update_ui()

func start_orders(initial_count := 2):
	orders.clear()
	_next_order_number = 1

	for i in range(initial_count):
		generate_order()

	update_ui()

func _process(delta):
	var expired_indexes = []
	var orders_changed := false

	for i in range(orders.size()):
		orders[i]["time_left"] -= delta

		if orders[i]["time_left"] <= 0:
			expired_indexes.append(i)

	for i in range(expired_indexes.size() - 1, -1, -1):
		var index = expired_indexes[i]
		print("ORDER FAILED : #%d %s" % [orders[index]["order_number"], readable_single_order_text(orders[index]["stack"])])
		orders.remove_at(index)
		emit_signal("order_expired")
		orders_changed = true

	var before_count := orders.size()
	while orders.size() < MAX_ORDERS and available_orders.size() > 0:
		generate_order()
	if orders.size() != before_count:
		orders_changed = true

	if orders_changed:
		update_ui()
	else:
		_refresh_order_times()

func generate_order():
	if orders.size() >= MAX_ORDERS:
		return

	if available_orders.is_empty():
		print("No available orders for this level")
		return

	var new_order = {
		"order_number": _next_order_number,
		"stack": available_orders.pick_random().duplicate(),
		"time_left": ORDER_TIME,
		"time_max": ORDER_TIME
	}

	_next_order_number += 1
	orders.append(new_order)

func _refresh_order_times() -> void:
	if orders_container == null:
		return

	for idx in range(orders.size()):
		if idx >= orders_container.get_child_count():
			break
		var card = orders_container.get_child(idx)
		if card.has_method("refresh_time"):
			card.refresh_time(orders[idx]["time_left"], get_order_border_color(orders[idx]))

func normalize_stack(stack: Array) -> Array:
	if stack.size() < 3:
		return stack.duplicate()
	var result := stack.duplicate()
	var middle: Array = result.slice(1, result.size() - 1)
	middle.sort()
	for i in range(middle.size()):
		result[i + 1] = middle[i]
	return result


func stacks_match(served_stack: Array, order_stack: Array) -> bool:
	return normalize_stack(served_stack) == normalize_stack(order_stack)


func evaluate_stack(served_stack: Array) -> Dictionary:
	for i in range(orders.size()):
		if stacks_match(served_stack, orders[i]["stack"]):
			return {
				"success": true,
				"order_number": orders[i]["order_number"],
				"index": i,
			}

	print("FAIL (servi : ", readable_single_order_text(served_stack), ")")
	return {"success": false, "served_text": order_ingredients_text(served_stack)}


func resolve_success(index: int) -> void:
	var card: Node = _get_card_at(index)
	if card != null and card.has_method("play_success"):
		await card.play_success()

	orders.remove_at(index)

	while orders.size() < MAX_ORDERS and available_orders.size() > 0:
		generate_order()

	update_ui()


func play_fail_feedback() -> void:
	if orders_container == null:
		return

	for idx in range(orders_container.get_child_count()):
		var card = orders_container.get_child(idx)
		if card.has_method("play_fail_shake") and idx < orders.size():
			card.play_fail_shake()


func _get_card_at(idx: int) -> Node:
	if orders_container == null or idx >= orders_container.get_child_count():
		return null
	return orders_container.get_child(idx)


func update_ui() -> void:
	if orders_container == null:
		return

	for child in orders_container.get_children():
		child.queue_free()

	for idx in range(orders.size()):
		var order = orders[idx]
		var card: PanelContainer = OrderCardScene.instantiate()
		orders_container.add_child(card)
		card.setup(
			order["order_number"],
			order_ingredients_text(order["stack"]),
			order["time_left"],
			get_order_border_color(order)
		)

func get_order_border_color(order) -> Color:
	var ratio = order["time_left"] / order["time_max"]

	if ratio > 0.6:
		return Color(0.42, 0.796, 0.467, 1)
	elif ratio > 0.3:
		return Color(1.0, 0.65, 0.2, 1)
	else:
		return Color(1.0, 0.42, 0.42, 1)

func order_ingredients_text(order_stack: Array) -> String:
	var parts: PackedStringArray = []
	for ingredient_type in order_stack:
		if ingredient_type >= 0 and ingredient_type < INGREDIENT_NAMES.size():
			parts.append(INGREDIENT_NAMES[ingredient_type])
	return " · ".join(parts)

func readable_single_order_text(order_stack: Array) -> String:
	var text = ""
	for i in range(order_stack.size()):
		text += INGREDIENT_NAMES[order_stack[i]]
		if i < order_stack.size() - 1:
			text += " → "
	return text
