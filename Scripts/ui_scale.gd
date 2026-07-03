extends Node

signal scale_changed

const REFERENCE_MIN_DIM := 800.0
const MIN_SCALE := 0.9
const MAX_SCALE := 2.0


func _ready() -> void:
	get_viewport().size_changed.connect(_on_viewport_changed)


func _on_viewport_changed() -> void:
	scale_changed.emit()


func get_scale() -> float:
	var viewport_size := get_viewport().get_visible_rect().size
	var min_dim := minf(viewport_size.x, viewport_size.y)
	return clampf(min_dim / REFERENCE_MIN_DIM, MIN_SCALE, MAX_SCALE)


func font(base: int) -> int:
	return maxi(10, roundi(base * get_scale()))


func px(base: float) -> float:
	return base * get_scale()


func vec2(base: Vector2) -> Vector2:
	return base * get_scale()


func apply_label(label: Label, base: int) -> void:
	label.set_meta("ui_base_font", base)
	label.add_theme_font_size_override("font_size", font(base))


func apply_button(button: Button, font_base: int, min_size: Vector2 = Vector2.ZERO) -> void:
	button.set_meta("ui_base_font", font_base)
	button.add_theme_font_size_override("font_size", font(font_base))
	if min_size != Vector2.ZERO:
		button.set_meta("ui_base_min_size", min_size)
		button.custom_minimum_size = vec2(min_size)


func apply_panel_min_width(panel: PanelContainer, base_width: float) -> void:
	panel.set_meta("ui_base_min_width", base_width)
	panel.custom_minimum_size.x = px(base_width)


func refresh_control_tree(root: Node) -> void:
	if root is Control:
		_refresh_control(root)

	for child in root.get_children():
		refresh_control_tree(child)


func _refresh_control(root: Control) -> void:
	if root is Label and root.has_meta("ui_base_font"):
		root.add_theme_font_size_override("font_size", font(root.get_meta("ui_base_font")))
	elif root is Button:
		if root.has_meta("ui_base_font"):
			root.add_theme_font_size_override("font_size", font(root.get_meta("ui_base_font")))
		if root.has_meta("ui_base_min_size"):
			root.custom_minimum_size = vec2(root.get_meta("ui_base_min_size"))
	elif root is PanelContainer and root.has_meta("ui_base_min_width"):
		root.custom_minimum_size.x = px(root.get_meta("ui_base_min_width"))
