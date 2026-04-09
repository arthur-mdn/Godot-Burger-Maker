extends Node

var current_order = null

func generate_order():
	var orders = [
		[0, 1, 0], # bun steak bun
		[0, 1, 2, 0], # bun steak cheese bun
		[0, 1, 3, 0], # bun steak tomato bun
	]

	current_order = orders.pick_random()

	print("ORDER :", readable_order())

func readable_order():
	var names = ["BUN", "STEAK", "CHEESE", "TOMATO", "SALAD", "ONION"]

	var result = []
	for i in current_order:
		result.append(names[i])

	return result

func validate(item):
	if item.stack == current_order:
		print("SUCCESS")
	else:
		print("FAIL")

func _ready():
	print("OrderManager OK")
	generate_order()
