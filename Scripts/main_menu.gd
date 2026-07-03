extends Control

@onready var title_label: Label = $CenterContainer/VBoxContainer/TitleLabel
@onready var play_button: Button = $CenterContainer/VBoxContainer/PlayButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitButton
@onready var menu_box: VBoxContainer = $CenterContainer/VBoxContainer


func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	UiScale.scale_changed.connect(_apply_ui_scale)
	_apply_ui_scale()


func _apply_ui_scale() -> void:
	UiScale.apply_label(title_label, 52)
	UiScale.apply_button(play_button, 22, Vector2(220, 52))
	UiScale.apply_button(quit_button, 22, Vector2(220, 52))
	menu_box.add_theme_constant_override("separation", roundi(UiScale.px(16.0)))
	UiScale.refresh_control_tree(self)


func _on_play_pressed() -> void:
	GameState.go_to_level_select()


func _on_quit_pressed() -> void:
	get_tree().quit()
