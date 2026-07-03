extends Node

var levels = [
	{
		"name": "Niveau 1",
		"time_limit": 120.0,
		"max_failures": 3,
		"target_success": 4,
		"active_stations": [
			"Dispenser_Bun",
			"Dispenser_Steak",
			"Dispenser_Cheese",
			"Cooking_1",
			"Trash",
			"ServingStation",
			"Slot_1",
			"Slot_2"
		],
		"allowed_orders": [
			[0, 1, 0],
			[0, 1, 2, 0]
		]
	},
	{
		"name": "Niveau 2",
		"time_limit": 120.0,
		"max_failures": 3,
		"target_success": 5,
		"active_stations": [
			"Dispenser_Bun",
			"Dispenser_Steak",
			"Dispenser_Cheese",
			"Dispenser_Tomato",
			"Cooking_1",
			"Cutting_1",
			"Trash",
			"ServingStation",
			"Slot_1",
			"Slot_2",
			"Slot_3"
		],
		"allowed_orders": [
			[0, 1, 0],
			[0, 1, 2, 0],
			[0, 1, 3, 0]
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
