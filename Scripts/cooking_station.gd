extends Node3D

@onready var progress_bg   = $ProgressBg
@onready var progress_mesh = $ProgressMesh

const COOK_TIME        := 5.0
const BURN_TIME        := 3.0
const RECOOK_BURN_TIME := 3.0
const HALF_WIDTH       := 0.6   # demi-largeur du mesh (BoxMesh size.x = 1.2)

var current_item = null
var _phase        := ""
var _timer        := 0.0
var _phase_duration := 0.0

func _ready():
	progress_bg.visible   = false
	progress_mesh.visible = false

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

# ── Barre ─────────────────────────────────────────────────────────────────────

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

# ── Slot interface ────────────────────────────────────────────────────────────

func place_item(item) -> bool:
	if current_item != null:
		return false
	if item.type != item.ItemType.STEAK:
		print("PAS UN STEAK")
		return false

	current_item           = item
	item.current_slot      = self
	item.global_position   = global_position + Vector3(0, 0.1, 0)
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
