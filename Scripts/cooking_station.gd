extends Node3D

const COOK_SURFACE_PADDING := 0.02
const PAN_STEAK_SURFACE_INSET := 0.06
const PROGRESS_BAR_HEIGHT := 0.42

signal item_pickup_requested(item)

@onready var pan: Node3D = $Visual/Pan
@onready var pickup_area: Area3D = $PickupArea
@onready var progress_bg = $ProgressBg
@onready var progress_mesh = $ProgressMesh

const COOK_TIME        := 5.0
const BURN_TIME        := 3.0
const RECOOK_BURN_TIME := 3.0
const HALF_WIDTH       := 0.6

var current_item = null
var _phase        := ""
var _timer        := 0.0
var _phase_duration := 0.0
var _item_drop_offset := Vector3.ZERO

func _ready():
	add_to_group("cooking_station")
	progress_bg.visible   = false
	progress_mesh.visible = false
	pickup_area.input_event.connect(_on_pickup_area_input)
	call_deferred("_update_drop_points")

func _update_drop_points() -> void:
	if not is_instance_valid(pan):
		return
	var pan_surface_y := _pan_cook_surface_y(pan)
	_item_drop_offset = Vector3(0, pan_surface_y + COOK_SURFACE_PADDING, 0)
	var progress_y := pan_surface_y + PROGRESS_BAR_HEIGHT
	progress_bg.position.y = progress_y
	progress_mesh.position.y = progress_y + 0.01

func _pan_cook_surface_y(pan_node: Node3D) -> float:
	var aabb := _combined_mesh_aabb(pan_node)
	if aabb.size.length_squared() < 0.000001:
		return pan_node.position.y + PAN_STEAK_SURFACE_INSET
	return pan_node.position.y + aabb.position.y + PAN_STEAK_SURFACE_INSET

func _combined_mesh_aabb(root: Node3D) -> AABB:
	var result := AABB()
	var has_aabb := false
	for mesh_instance in root.find_children("*", "MeshInstance3D", true, false):
		if mesh_instance.mesh == null:
			continue
		var local_aabb: AABB = mesh_instance.transform * mesh_instance.mesh.get_aabb()
		if not has_aabb:
			result = local_aabb
			has_aabb = true
		else:
			result = result.merge(local_aabb)
	return result

func _on_pickup_area_input(_camera, event, _position, _normal, _shape_idx) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if current_item == null:
		return
	var item = remove_item()
	if item:
		item.current_slot = null
		emit_signal("item_pickup_requested", item)

func _process(delta: float):
	if _phase == "" or not is_instance_valid(current_item):
		return

	_timer += delta
	var ratio: float = clamp(_timer / _phase_duration, 0.0, 1.0)
	_update_progress_bar(ratio)

	if _timer < _phase_duration:
		return

	match _phase:
		"cooking":
			current_item.cook_state        = current_item.CookState.COOKED
			current_item.visual_cook_state = current_item.CookState.COOKED
			current_item.rebuild_visual()
			_start_phase("burning", BURN_TIME)

		"burning":
			current_item.cook_state        = current_item.CookState.BURNT
			current_item.visual_cook_state = current_item.CookState.BURNT
			current_item.rebuild_visual()
			_stop_bar()

func _update_progress_bar(pct: float):
	if not is_instance_valid(progress_mesh):
		return
	var p: float = maxf(pct, 0.01)
	progress_mesh.scale.x    = p
	progress_mesh.position.x = -HALF_WIDTH + HALF_WIDTH * p

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if _phase == "cooking":
		mat.albedo_color = Color(0.1, 0.85, 0.1)
	else:
		mat.albedo_color = Color(0.9, 0.15 * (1.0 - pct), 0.0)
	progress_mesh.material_override = mat

func _start_phase(phase: String, duration: float):
	_phase          = phase
	_timer          = 0.0
	_phase_duration = duration
	progress_bg.visible   = true
	progress_mesh.visible = true
	_update_progress_bar(0.0)

func _stop_bar():
	_phase = ""
	progress_bg.visible   = false
	progress_mesh.visible = false

func place_item(item) -> bool:
	if current_item != null:
		return false
	if item.type != item.ItemType.STEAK:
		print("PAS UN STEAK")
		return false

	current_item           = item
	item.current_slot      = self
	item.global_position   = global_position + _item_drop_offset
	item.cooking_id       += 1
	_begin_cooking(item)
	return true

func _begin_cooking(item):
	if item.cook_state == item.CookState.BURNT:
		return

	if item.cook_state == item.CookState.COOKED:
		item.cook_state        = item.CookState.COOKING
		item.visual_cook_state = item.CookState.COOKED
		item.rebuild_visual()
		_start_phase("burning", RECOOK_BURN_TIME)
	else:
		item.cook_state        = item.CookState.COOKING
		item.visual_cook_state = item.CookState.COOKING
		item.rebuild_visual()
		_start_phase("cooking", COOK_TIME)

func remove_item():
	var phase_at_removal := _phase
	_stop_bar()

	if current_item:
		current_item.cooking_id += 1
		if phase_at_removal == "cooking":
			current_item.cook_state        = current_item.CookState.RAW
			current_item.visual_cook_state = current_item.CookState.RAW
			current_item.rebuild_visual()
		elif phase_at_removal == "burning":
			current_item.cook_state        = current_item.CookState.COOKED
			current_item.visual_cook_state = current_item.CookState.COOKED
			current_item.rebuild_visual()

	var item = current_item
	current_item = null
	return item
