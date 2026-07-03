extends Control

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var level_list: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/LevelList
@onready var back_button: Button = $MarginContainer/VBoxContainer/BackButton
@onready var content_box: VBoxContainer = $MarginContainer/VBoxContainer
@onready var margin_container: MarginContainer = $MarginContainer


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	UiScale.scale_changed.connect(_on_scale_changed)
	_populate_levels()
	_apply_ui_scale()


func _on_scale_changed() -> void:
	_apply_ui_scale()


func _apply_ui_scale() -> void:
	UiScale.apply_label(title_label, 40)
	UiScale.apply_button(back_button, 20, Vector2(0, 52))
	content_box.add_theme_constant_override("separation", roundi(UiScale.px(20.0)))
	level_list.add_theme_constant_override("separation", roundi(UiScale.px(12.0)))

	var margin := roundi(UiScale.px(40.0))
	margin_container.add_theme_constant_override("margin_left", margin)
	margin_container.add_theme_constant_override("margin_top", margin)
	margin_container.add_theme_constant_override("margin_right", margin)
	margin_container.add_theme_constant_override("margin_bottom", margin)

	for child in level_list.get_children():
		if child is Button:
			UiScale.apply_button(child, 20, Vector2(0, 52))

	UiScale.refresh_control_tree(self)


func _populate_levels() -> void:
	for child in level_list.get_children():
		child.queue_free()

	for i in range(LevelManager.get_level_count()):
		var level_data = LevelManager.levels[i]
		var button := Button.new()
		var unlocked := GameState.is_level_unlocked(i)
		var best := GameState.get_best_score(i)

		if unlocked:
			var label: String = "%d. %s" % [i + 1, level_data["name"]]
			if best > 0:
				label += "  (meilleur : %d)" % best
			button.text = label
			var level_index := i
			button.pressed.connect(func(): _on_level_selected(level_index))
		else:
			button.text = "%d. %s  (verrouillé)" % [i + 1, level_data["name"]]
			button.disabled = true

		UiScale.apply_button(button, 20, Vector2(0, 52))
		level_list.add_child(button)


func _on_level_selected(index: int) -> void:
	GameState.start_level(index)


func _on_back_pressed() -> void:
	GameState.go_to_menu()
