extends Node

var orders = []
@export var order_label: RichTextLabel

func generate_order():
	var pool = [
		[0, 1, 0],
		[0, 1, 2, 0],
		[0, 1, 3, 0],
	]

	var new_order = pool.pick_random()
	orders.append(new_order)

	update_ui()

func readable_order_text():
	var names = ["BUN", "STEAK", "CHEESE", "TOMATO", "SALAD", "ONION"]

	var text = ""

	for order in orders:
		for i in range(order.size()):
			text += names[order[i]]
			if i < order.size() - 1:
				text += " → "

		text += "\n"

	return text

func update_ui(highlight_index := -1, color := Color.WHITE):
	var names = ["BUN", "STEAK", "CHEESE", "TOMATO", "SALAD", "ONION"]

	var text = ""

	for idx in range(orders.size()):
		var order = orders[idx]

		var line = ""
		for i in range(order.size()):
			line += names[order[i]]
			if i < order.size() - 1:
				line += " → "

		# 🎯 appliquer couleur UNIQUEMENT sur la ligne concernée
		if idx == highlight_index:
			line = "[color=" + color.to_html() + "]" + line + "[/color]"

		text += line + "\n"

	order_label.clear()
	order_label.append_text(text)

func validate(item):
	for i in range(orders.size()):
		if item.stack == orders[i]:
			print("SUCCESS")

			# 🟢 highlight uniquement la bonne ligne
			update_ui(i, Color.GREEN)

			await get_tree().create_timer(0.5).timeout

			orders.remove_at(i)

			generate_order()
			update_ui()
			return

	print("FAIL")

	# 🔴 tout rouge (optionnel)
	order_label.modulate = Color.RED

	await get_tree().create_timer(1).timeout

	order_label.modulate = Color.WHITE
	update_ui()


func _ready():
	print("OrderManager OK")

	generate_order()
	generate_order()
