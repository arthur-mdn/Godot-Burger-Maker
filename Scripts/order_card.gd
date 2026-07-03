extends PanelContainer

const BASE_NUMBER_FONT := 14
const BASE_INGREDIENTS_FONT := 16
const BASE_TIME_FONT := 19
const BASE_STATUS_FONT := 24
const BASE_CARD_WIDTH := 360.0
const BASE_MARGIN := 10.0
const BASE_ROW_SEPARATION := 8.0

@onready var _number_label: Label = $Margin/Row/Number
@onready var _ingredients_label: Label = $Margin/Row/Ingredients
@onready var _time_label: Label = $Margin/Row/Time
@onready var _status_label: Label = $Margin/Row/Status
@onready var _margin: MarginContainer = $Margin
@onready var _row: HBoxContainer = $Margin/Row

var _panel_style: StyleBoxFlat
var _urgency_color: Color = Color(0.42, 0.796, 0.467, 1)


func _ready() -> void:
	var base_style := get_theme_stylebox("panel")
	if base_style is StyleBoxFlat:
		_panel_style = base_style.duplicate() as StyleBoxFlat
		add_theme_stylebox_override("panel", _panel_style)

	UiScale.scale_changed.connect(_apply_scale)
	_apply_scale()


func _apply_scale() -> void:
	_number_label.add_theme_font_size_override("font_size", UiScale.font(BASE_NUMBER_FONT))
	_ingredients_label.add_theme_font_size_override("font_size", UiScale.font(BASE_INGREDIENTS_FONT))
	_time_label.add_theme_font_size_override("font_size", UiScale.font(BASE_TIME_FONT))
	_status_label.add_theme_font_size_override("font_size", UiScale.font(BASE_STATUS_FONT))
	custom_minimum_size.x = UiScale.px(BASE_CARD_WIDTH)
	_margin.add_theme_constant_override("margin_left", roundi(UiScale.px(BASE_MARGIN)))
	_margin.add_theme_constant_override("margin_right", roundi(UiScale.px(BASE_MARGIN)))
	_margin.add_theme_constant_override("margin_top", roundi(UiScale.px(5.0)))
	_margin.add_theme_constant_override("margin_bottom", roundi(UiScale.px(5.0)))
	_row.add_theme_constant_override("separation", roundi(UiScale.px(BASE_ROW_SEPARATION)))


func _ensure_panel_style() -> void:
	if _panel_style != null:
		return
	var base_style := get_theme_stylebox("panel")
	if base_style is StyleBoxFlat:
		_panel_style = base_style.duplicate() as StyleBoxFlat
		add_theme_stylebox_override("panel", _panel_style)


func setup(order_number: int, ingredients_text: String, time_left: float, border_color: Color) -> void:
	_ensure_panel_style()
	_apply_scale()
	_urgency_color = border_color
	_number_label.text = "#%d" % order_number
	_ingredients_label.text = ingredients_text
	_status_label.visible = false
	_time_label.visible = true
	refresh_time(time_left, border_color)


func refresh_time(time_left: float, border_color: Color) -> void:
	_ensure_panel_style()
	_urgency_color = border_color
	_time_label.text = str(int(ceil(time_left))) + "s"
	if _panel_style:
		_panel_style.border_color = border_color


func play_success() -> void:
	_ensure_panel_style()
	_time_label.visible = false
	_status_label.visible = true
	_status_label.text = "✓"

	if _panel_style:
		_panel_style.border_color = Color(0.25, 0.95, 0.4, 1)
		_panel_style.bg_color = Color(0.08, 0.22, 0.12, 0.98)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.06, 1.06), 0.15)
	tween.tween_property(self, "scale", Vector2.ONE, 0.2)
	tween.tween_interval(0.2)
	await tween.finished


func play_fail_shake() -> void:
	_ensure_panel_style()
	if _panel_style:
		_panel_style.border_color = Color(1.0, 0.32, 0.32, 1)

	var shake := UiScale.px(6.0)
	var start_x := position.x
	var tween := create_tween()
	for _i in range(3):
		tween.tween_property(self, "position:x", start_x + shake, 0.035)
		tween.tween_property(self, "position:x", start_x - shake, 0.035)
	tween.tween_property(self, "position:x", start_x, 0.035)
	tween.tween_callback(func() -> void:
		if _panel_style:
			_panel_style.border_color = _urgency_color
	)
