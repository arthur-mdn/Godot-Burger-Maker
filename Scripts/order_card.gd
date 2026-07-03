extends PanelContainer

@onready var _number_label: Label = $Margin/Row/Number
@onready var _ingredients_label: Label = $Margin/Row/Ingredients
@onready var _time_label: Label = $Margin/Row/Time

var _panel_style: StyleBoxFlat


func _ready() -> void:
	var base_style := get_theme_stylebox("panel")
	if base_style is StyleBoxFlat:
		_panel_style = base_style.duplicate() as StyleBoxFlat
		add_theme_stylebox_override("panel", _panel_style)


func _ensure_panel_style() -> void:
	if _panel_style != null:
		return
	var base_style := get_theme_stylebox("panel")
	if base_style is StyleBoxFlat:
		_panel_style = base_style.duplicate() as StyleBoxFlat
		add_theme_stylebox_override("panel", _panel_style)


func setup(order_number: int, ingredients_text: String, time_left: float, border_color: Color) -> void:
	_ensure_panel_style()
	_number_label.text = "#%d" % order_number
	_ingredients_label.text = ingredients_text
	refresh_time(time_left, border_color)


func refresh_time(time_left: float, border_color: Color) -> void:
	_ensure_panel_style()
	_time_label.text = str(int(ceil(time_left))) + "s"
	if _panel_style:
		_panel_style.border_color = border_color
