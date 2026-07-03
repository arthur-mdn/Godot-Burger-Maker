extends Control

@onready var level_list: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/LevelList
@onready var back_button: Button = $MarginContainer/VBoxContainer/BackButton


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_populate_levels()


func _populate_levels() -> void:
	for child in level_list.get_children():
		child.queue_free()

	for i in range(LevelManager.get_level_count()):
		var level_data = LevelManager.levels[i]
		var button := Button.new()
		var unlocked := GameState.is_level_unlocked(i)
		var best := GameState.get_best_score(i)

		if unlocked:
			var label: String = level_data["name"]
			if best > 0:
				label += "  (meilleur : %d)" % best
			button.text = label
			var level_index := i
			button.pressed.connect(func(): _on_level_selected(level_index))
		else:
			button.text = level_data["name"] + "  (verrouillé)"
			button.disabled = true

		level_list.add_child(button)


func _on_level_selected(index: int) -> void:
	GameState.start_level(index)


func _on_back_pressed() -> void:
	GameState.go_to_menu()
