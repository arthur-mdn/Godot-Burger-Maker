extends Node3D

const FeedbackFont := preload("res://Assets/Fonts/Nunito-ExtraBold.woff")
const FEEDBACK_ANCHOR := Vector3(-0.75, 2.0, 0.35)

@export var order_manager: Node
@export var game_manager: Node

@onready var _visual: Node3D = $Visual

var _feedback_busy := false
var _feedback_layer: CanvasLayer
var _feedback_label: Label
var _feedback_tween: Tween
var _camera: Camera3D


func _ready() -> void:
	_setup_screen_feedback()


func _setup_screen_feedback() -> void:
	_feedback_layer = CanvasLayer.new()
	_feedback_layer.layer = 12
	add_child(_feedback_layer)

	_feedback_label = Label.new()
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_feedback_label.add_theme_font_override("font", FeedbackFont)
	_feedback_label.visible = false
	_feedback_layer.add_child(_feedback_label)


func place_item(item):
	if order_manager == null:
		return false

	var served_stack = item.stack.duplicate()
	item.queue_free()

	_process_serving(served_stack)
	return true


func _process_serving(served_stack) -> void:
	if _feedback_busy:
		return

	_feedback_busy = true
	var result: Dictionary = order_manager.evaluate_stack(served_stack)

	if result.get("success", false):
		_flash_visual(true)
		_begin_feedback("Commande #%d validée !" % result["order_number"], true)
		await order_manager.resolve_success(result["index"])
		await _wait_feedback_tween()
		if game_manager != null and game_manager.has_method("register_success"):
			game_manager.register_success()
	else:
		_flash_visual(false)
		order_manager.play_fail_feedback()
		var message := "Commande incorrecte"
		var served_text: String = result.get("served_text", "")
		if served_text != "":
			message += "\n" + served_text
		_begin_feedback(message, false)
		await _wait_feedback_tween()
		if game_manager != null and game_manager.has_method("register_fail"):
			game_manager.register_fail()

	_feedback_busy = false


func _scaled_font_size() -> int:
	return UiScale.font(30)


func _scaled_outline_size() -> int:
	return maxi(4, roundi(_scaled_font_size() * 0.14))


func _scaled_float_offset() -> float:
	return UiScale.px(36.0)


func _feedback_world_pos() -> Vector3:
	return global_position + global_transform.basis * FEEDBACK_ANCHOR


func _position_feedback_label() -> void:
	if _camera == null or not is_instance_valid(_camera):
		_camera = get_viewport().get_camera_3d()
	var screen_pos := _camera.unproject_position(_feedback_world_pos())
	_feedback_label.reset_size()
	_feedback_label.position = screen_pos - _feedback_label.size * 0.5


func _begin_feedback(text: String, success: bool) -> void:
	if _feedback_tween != null and _feedback_tween.is_running():
		_feedback_tween.kill()

	var font_size := _scaled_font_size()
	_feedback_label.add_theme_font_size_override("font_size", font_size)
	_feedback_label.add_theme_constant_override("outline_size", _scaled_outline_size())
	_feedback_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_feedback_label.text = text
	_feedback_label.modulate = Color(0.35, 1.0, 0.45) if success else Color(1.0, 0.35, 0.35)
	_feedback_label.visible = true
	_position_feedback_label()
	call_deferred("_position_feedback_label")

	var start_y := _feedback_label.position.y
	_feedback_tween = create_tween()
	_feedback_tween.set_parallel(true)
	_feedback_tween.tween_property(_feedback_label, "position:y", start_y - _scaled_float_offset(), 0.75)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_feedback_tween.tween_property(_feedback_label, "modulate:a", 0.0, 0.55).set_delay(0.35)
	_feedback_tween.chain().tween_callback(_finish_feedback)


func _finish_feedback() -> void:
	_feedback_label.visible = false
	_feedback_label.modulate.a = 1.0
	_feedback_tween = null


func _wait_feedback_tween() -> void:
	if _feedback_tween != null:
		await _feedback_tween.finished


func _flash_visual(success: bool) -> void:
	var light := OmniLight3D.new()
	_visual.add_child(light)
	light.position = Vector3(0, 1.8, 0.5)
	light.light_color = Color(0.45, 1.0, 0.55) if success else Color(1.0, 0.35, 0.35)
	light.light_energy = 2.5
	light.omni_range = 3.5

	var flash := create_tween()
	flash.tween_property(light, "light_energy", 0.0, 0.45)
	flash.tween_callback(light.queue_free)
