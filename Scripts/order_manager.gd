extends Node

var current_order = null
@export var order_label: Label

func generate_order():
	var orders = [
		[0, 1, 0],
		[0, 1, 2, 0],
		[0, 1, 3, 0],
	]

	current_order = orders.pick_random()

	var text = "Commande : " + readable_order_text()

	print(text)

	if order_label:
		order_label.text = text


func readable_order():
	var names = ["BUN", "STEAK", "CHEESE", "TOMATO", "SALAD", "ONION"]

	var result: Array[String] = []
	for i in current_order:
		result.append(names[i])

	return result


func readable_order_text():
	var parts = readable_order()
	var text = ""

	for i in range(parts.size()):
		text += parts[i]
		if i < parts.size() - 1:
			text += " → "

	return text


func validate(item):
	if item.stack == current_order:
		print("SUCCESS")
		order_label.modulate = Color.GREEN
	else:
		print("FAIL")
		order_label.modulate = Color.RED

	await get_tree().create_timer(1).timeout
	order_label.modulate = Color.WHITE

	generate_order()


func _ready():
	print("OrderManager OK")
	generate_order()
