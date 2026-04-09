extends Node

var orders = []
var available_orders = []
@export var order_label: RichTextLabel

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

	for i in range(initial_count):
		generate_order()

	update_ui()

func _process(delta):
	var expired_indexes = []

	for i in range(orders.size()):
		orders[i]["time_left"] -= delta

		if orders[i]["time_left"] <= 0:
			expired_indexes.append(i)

	for i in range(expired_indexes.size() - 1, -1, -1):
		var index = expired_indexes[i]
		print("ORDER FAILED :", readable_single_order_text(orders[index]["stack"]))
		orders.remove_at(index)

	while orders.size() < MAX_ORDERS and available_orders.size() > 0:
		generate_order()

	update_ui()

func generate_order():
	if orders.size() >= MAX_ORDERS:
		return

	if available_orders.is_empty():
		print("No available orders for this level")
		return

	var new_order = {
		"stack": available_orders.pick_random().duplicate(),
		"time_left": ORDER_TIME,
		"time_max": ORDER_TIME
	}

	orders.append(new_order)
	update_ui()

func validate(item):
	for i in range(orders.size()):
		if item.stack == orders[i]["stack"]:
			print("SUCCESS")

			update_ui(i, Color.GREEN)

			await get_tree().create_timer(0.5).timeout

			orders.remove_at(i)

			while orders.size() < MAX_ORDERS and available_orders.size() > 0:
				generate_order()

			update_ui()
			return true

	print("FAIL")
	update_ui(-1, Color.RED)

	await get_tree().create_timer(0.5).timeout
	update_ui()
	return false

func update_ui(highlight_index := -2, override_color := Color.WHITE):
	if order_label == null:
		return

	var text = ""

	for idx in range(orders.size()):
		var order = orders[idx]
		var line = "Commande " + str(idx + 1) + " : "
		line += readable_single_order_text(order["stack"])
		line += "   [" + str(int(ceil(order["time_left"]))) + "s]"

		var line_color = get_order_color(order)

		if highlight_index == idx:
			line_color = override_color
		elif highlight_index == -1:
			line_color = override_color

		line = "[color=" + line_color.to_html() + "]" + line + "[/color]"

		text += line
		if idx < orders.size() - 1:
			text += "\n"

	order_label.clear()
	order_label.append_text(text)

func get_order_color(order) -> Color:
	var ratio = order["time_left"] / order["time_max"]

	if ratio > 0.6:
		return Color.WHITE
	elif ratio > 0.3:
		return Color.ORANGE
	else:
		return Color.RED

func readable_single_order_text(order_stack: Array) -> String:
	var names = ["BUN", "STEAK", "CHEESE", "TOMATO", "SALAD", "ONION"]

	var text = ""
	for i in range(order_stack.size()):
		text += names[order_stack[i]]
		if i < order_stack.size() - 1:
			text += " → "

	return text
