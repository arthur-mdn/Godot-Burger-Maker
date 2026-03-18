extends Node3D

const CHOP_DURATION: float = 3.0

var current_item = null
var chop_progress: float = 0.0
var is_chopping: bool = false

@onready var progress_mesh: MeshInstance3D = $ProgressMesh

func place_item(item) -> bool:
	if current_item != null:
		return false

	if item.type != item.ItemType.TOMATO and item.type != item.ItemType.ONION:
		print("PLANCHE : uniquement TOMATE ou OIGNON")
		return false

	if item.is_chopped:
		print("PLANCHE : déjà coupé")
		return false

	current_item = item
	item.current_slot = self
	item.global_position = global_position + Vector3(0, 0.3, 0)

	chop_progress = 0.0
	is_chopping = true
	_update_progress_bar(0.0)
	return true

func _process(delta: float):
	if not is_chopping or current_item == null:
		return

	chop_progress = minf(chop_progress + delta / CHOP_DURATION, 1.0)
	_update_progress_bar(chop_progress)

	if chop_progress >= 1.0:
		is_chopping = false
		current_item.is_chopped = true
		current_item.rebuild_visual()
		print("✂️ COUPÉ !")

func _update_progress_bar(pct: float):
	if not is_instance_valid(progress_mesh):
		return
	# La barre fait 1.2 d'unité de large (BoxMesh size.x).
	# Le fond (ProgressBg) va de -0.6 à +0.6 en X local.
	# On scale depuis le centre → on compense la position pour ancrer à gauche.
	var half_width := 0.6  # moitié de la taille du BoxMesh (1.2 / 2)
	var p := maxf(pct, 0.01)
	progress_mesh.scale.x = p
	progress_mesh.position.x = -half_width + half_width * p
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0 - pct, pct, 0.0)
	progress_mesh.material_override = mat

func remove_item():
	is_chopping = false
	chop_progress = 0.0
	_update_progress_bar(0.0)

	if current_item:
		current_item.current_slot = null
	var item = current_item
	current_item = null
	return item
