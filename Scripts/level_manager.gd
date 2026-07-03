extends Node

const BASE_STATIONS := ["Trash", "ServingStation"]

var levels = [
	{
		"name": "Premier flip",
		"time_limit": 150.0,
		"max_failures": 5,
		"target_success": 2,
		"active_stations": BASE_STATIONS + [
			"Dispenser_Bun",
			"Dispenser_Steak",
			"Cooking_1",
			"Slot_1"
		],
		"allowed_orders": [
			[0, 1, 0]
		]
	},
	{
		"name": "Fromage fondant",
		"time_limit": 140.0,
		"max_failures": 4,
		"target_success": 3,
		"active_stations": BASE_STATIONS + [
			"Dispenser_Bun",
			"Dispenser_Steak",
			"Dispenser_Cheese",
			"Cooking_1",
			"Slot_1",
			"Slot_2"
		],
		"allowed_orders": [
			[0, 1, 0],
			[0, 1, 2, 0]
		]
	},
	{
		"name": "Enchaînement",
		"time_limit": 130.0,
		"max_failures": 4,
		"target_success": 4,
		"active_stations": BASE_STATIONS + [
			"Dispenser_Bun",
			"Dispenser_Steak",
			"Dispenser_Cheese",
			"Cooking_1",
			"Slot_1",
			"Slot_2"
		],
		"allowed_orders": [
			[0, 1, 0],
			[0, 1, 2, 0]
		]
	},
	{
		"name": "Salade croquante",
		"time_limit": 130.0,
		"max_failures": 3,
		"target_success": 4,
		"active_stations": BASE_STATIONS + [
			"Dispenser_Bun",
			"Dispenser_Steak",
			"Dispenser_Cheese",
			"Dispenser_Salad",
			"Cooking_1",
			"Cutting_1",
			"Slot_1",
			"Slot_2"
		],
		"allowed_orders": [
			[0, 1, 0],
			[0, 1, 2, 0],
			[0, 1, 4, 0]
		]
	},
	{
		"name": "Tomate fraîche",
		"time_limit": 125.0,
		"max_failures": 3,
		"target_success": 4,
		"active_stations": BASE_STATIONS + [
			"Dispenser_Bun",
			"Dispenser_Steak",
			"Dispenser_Cheese",
			"Dispenser_Tomato",
			"Cooking_1",
			"Cutting_1",
			"Slot_1",
			"Slot_2"
		],
		"allowed_orders": [
			[0, 1, 0],
			[0, 1, 3, 0],
			[0, 1, 2, 3, 0]
		]
	},
	{
		"name": "Service rapide",
		"time_limit": 120.0,
		"max_failures": 3,
		"target_success": 5,
		"active_stations": BASE_STATIONS + [
			"Dispenser_Bun",
			"Dispenser_Steak",
			"Dispenser_Cheese",
			"Dispenser_Tomato",
			"Cooking_1",
			"Cooking_2",
			"Cutting_1",
			"Slot_1",
			"Slot_2",
			"Slot_3"
		],
		"allowed_orders": [
			[0, 1, 0],
			[0, 1, 2, 0],
			[0, 1, 3, 0],
			[0, 1, 2, 3, 0]
		]
	},
	{
		"name": "Oignon piquant",
		"time_limit": 115.0,
		"max_failures": 3,
		"target_success": 5,
		"active_stations": BASE_STATIONS + [
			"Dispenser_Bun",
			"Dispenser_Steak",
			"Dispenser_Cheese",
			"Dispenser_Tomato",
			"Dispenser_Onion",
			"Cooking_1",
			"Cooking_2",
			"Cutting_1",
			"Cutting_2",
			"Slot_1",
			"Slot_2",
			"Slot_3"
		],
		"allowed_orders": [
			[0, 1, 0],
			[0, 1, 3, 0],
			[0, 1, 5, 0],
			[0, 1, 2, 3, 0],
			[0, 1, 2, 5, 0]
		]
	},
	{
		"name": "Sans répit",
		"time_limit": 108.0,
		"max_failures": 2,
		"target_success": 6,
		"active_stations": BASE_STATIONS + [
			"Dispenser_Bun",
			"Dispenser_Steak",
			"Dispenser_Cheese",
			"Dispenser_Tomato",
			"Dispenser_Salad",
			"Dispenser_Onion",
			"Cooking_1",
			"Cooking_2",
			"Cutting_1",
			"Cutting_2",
			"Slot_1",
			"Slot_2",
			"Slot_3",
			"Slot_4"
		],
		"allowed_orders": [
			[0, 1, 2, 0],
			[0, 1, 3, 0],
			[0, 1, 5, 0],
			[0, 1, 2, 3, 0],
			[0, 1, 2, 4, 0],
			[0, 1, 2, 5, 0],
			[0, 1, 3, 4, 0]
		]
	},
	{
		"name": "Tout feu tout flamme",
		"time_limit": 102.0,
		"max_failures": 2,
		"target_success": 6,
		"active_stations": BASE_STATIONS + [
			"Dispenser_Bun",
			"Dispenser_Steak",
			"Dispenser_Cheese",
			"Dispenser_Tomato",
			"Dispenser_Salad",
			"Dispenser_Onion",
			"Cooking_1",
			"Cooking_2",
			"Cutting_1",
			"Cutting_2",
			"Slot_1",
			"Slot_2",
			"Slot_3",
			"Slot_4"
		],
		"allowed_orders": [
			[0, 1, 2, 3, 0],
			[0, 1, 2, 4, 0],
			[0, 1, 2, 5, 0],
			[0, 1, 3, 4, 0],
			[0, 1, 3, 5, 0],
			[0, 1, 2, 3, 4, 0],
			[0, 1, 2, 4, 5, 0]
		]
	},
	{
		"name": "Maître burger",
		"time_limit": 95.0,
		"max_failures": 2,
		"target_success": 7,
		"active_stations": BASE_STATIONS + [
			"Dispenser_Bun",
			"Dispenser_Steak",
			"Dispenser_Cheese",
			"Dispenser_Tomato",
			"Dispenser_Salad",
			"Dispenser_Onion",
			"Cooking_1",
			"Cooking_2",
			"Cutting_1",
			"Cutting_2",
			"Slot_1",
			"Slot_2",
			"Slot_3",
			"Slot_4"
		],
		"allowed_orders": [
			[0, 1, 0],
			[0, 1, 2, 0],
			[0, 1, 4, 0],
			[0, 1, 3, 0],
			[0, 1, 5, 0],
			[0, 1, 2, 3, 0],
			[0, 1, 2, 4, 5, 0]
		]
	}
]

var current_level_index := 0


func get_level_count() -> int:
	return levels.size()


func set_current_level(index: int) -> void:
	current_level_index = clampi(index, 0, levels.size() - 1)


func get_current_level():
	return levels[current_level_index]


func has_next_level() -> bool:
	return current_level_index < levels.size() - 1
