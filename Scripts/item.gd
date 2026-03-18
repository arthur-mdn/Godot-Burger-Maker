extends Node3D

enum ItemType { BUN, STEAK, CHEESE, TOMATO, SALAD, ONION }
enum CookState { NONE, RAW, COOKING, COOKED, BURNT }

@export var type: ItemType

signal clicked(item)

@onready var stack_root = $Visual/StackRoot
@onready var area = $Area3D

var current_slot = null
var stack = []
var cook_state = CookState.NONE
var visual_cook_state = CookState.NONE
var cooking_id = 0
var is_chopped: bool = false
var steak_visual_state = CookState.COOKED

func _ready():
	add_to_group("item")
	area.input_event.connect(_on_input_event)
	stack.append(type)
	if type == ItemType.STEAK:
		cook_state = CookState.RAW
		visual_cook_state = CookState.RAW
		steak_visual_state = CookState.RAW
	rebuild_visual()

func _on_input_event(_camera, event, _position, _normal, _shape_idx):
	if event is InputEventMouseButton \
	and event.pressed \
	and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("clicked", self)

# ── Règles de merge ───────────────────────────────────────────────────────────

func _is_ready_to_use(item) -> bool:
	match item.type:
		ItemType.STEAK:
			return item.cook_state == CookState.COOKED
		ItemType.TOMATO, ItemType.ONION:
			return item.is_chopped
		_:
			return true

func _bun_count() -> int:
	var n = 0
	for t in stack:
		if t == ItemType.BUN:
			n += 1
	return n

func can_merge(other) -> bool:
	if not _is_ready_to_use(other):
		print("MERGE : item non préparé")
		return false

	if other.type == ItemType.BUN:
		if _bun_count() >= 2:
			return false
		if _bun_count() == 1 and not (ItemType.STEAK in stack):
			return false
	else:
		if other.type in stack:
			print("MERGE : doublon ", other.type)
			return false

	return true

func merge(other):
	var t = other.type

	if t == ItemType.STEAK:
		steak_visual_state = other.visual_cook_state

	var insert_idx: int
	match t:
		ItemType.BUN:
			if _bun_count() == 0:
				insert_idx = 0              # pain du bas → tout en bas
			else:
				insert_idx = stack.size()   # pain du haut → tout en haut

		ItemType.STEAK:
			# Juste après le pain du bas s'il existe
			if stack.size() > 0 and stack[0] == ItemType.BUN:
				insert_idx = 1
			else:
				insert_idx = 0

		_:
			# Topping : avant le pain du HAUT uniquement (quand les 2 pains sont là)
			# Si seulement le pain du bas est présent, on ajoute après lui (= à la fin)
			if _bun_count() == 2 and stack.back() == ItemType.BUN:
				insert_idx = stack.size() - 1
			else:
				insert_idx = stack.size()

	stack.insert(insert_idx, t)
	other.queue_free()
	rebuild_visual()

	print("STACK :", stack)
	if is_complete():
		print("✅ BURGER COMPLET !")

# ── Visual ────────────────────────────────────────────────────────────────────

func _mesh_height_for(t: int) -> float:
	match t:
		ItemType.BUN:    return 0.3
		ItemType.STEAK:  return 0.2
		ItemType.CHEESE: return 0.1
		ItemType.TOMATO: return 0.06 if is_chopped else 0.12
		ItemType.SALAD:  return 0.15
		ItemType.ONION:  return 0.04 if is_chopped else 0.08
		_: return 0.1

func rebuild_visual():
	for child in stack_root.get_children():
		child.queue_free()

	stack_root.position = Vector3.ZERO

	var height = 0.0
	# Pain du haut semi-transparent uniquement quand les 2 pains sont posés et burger incomplet
	var has_top_bun = (_bun_count() == 2 and not is_complete())

	for i in range(stack.size()):
		var t = stack[i]
		var mesh = MeshInstance3D.new()
		var mesh_height = _mesh_height_for(t)

		match t:
			ItemType.BUN:
				mesh.mesh = BoxMesh.new()
				mesh.scale = Vector3(1, mesh_height, 1)
				var is_top_bun = has_top_bun and (i == stack.size() - 1)
				var color = Color(0.8, 0.6, 0.3, 0.35 if is_top_bun else 1.0)
				mesh.material_override = _mat(color, is_top_bun)

			ItemType.STEAK:
				mesh.mesh = BoxMesh.new()
				mesh.scale = Vector3(0.9, mesh_height, 0.9)
				var s = visual_cook_state if type == ItemType.STEAK else steak_visual_state
				match s:
					CookState.RAW:     mesh.material_override = _mat(Color(1.0, 0.3, 0.3))
					CookState.COOKING: mesh.material_override = _mat(Color(0.9, 0.25, 0.05))
					CookState.COOKED:  mesh.material_override = _mat(Color(0.4, 0.2, 0.1))
					CookState.BURNT:   mesh.material_override = _mat(Color(0.1, 0.1, 0.1))
					_:                 mesh.material_override = _mat(Color(0.4, 0.2, 0.1))

			ItemType.CHEESE:
				mesh.mesh = BoxMesh.new()
				mesh.scale = Vector3(0.9, mesh_height, 0.9)
				mesh.material_override = _mat(Color(1.0, 0.8, 0.2))

			ItemType.TOMATO:
				mesh.mesh = BoxMesh.new()
				mesh.scale = Vector3(0.9, mesh_height, 0.9)
				mesh.material_override = _mat(Color(1.0, 0.1, 0.1) if is_chopped else Color(1.0, 0.2, 0.2))

			ItemType.SALAD:
				mesh.mesh = BoxMesh.new()
				mesh.scale = Vector3(0.9, mesh_height, 0.9)
				mesh.material_override = _mat(Color(0.2, 0.8, 0.2))

			ItemType.ONION:
				mesh.mesh = BoxMesh.new()
				mesh.scale = Vector3(0.9, mesh_height, 0.9)
				mesh.material_override = _mat(Color(0.95, 0.85, 1.0) if is_chopped else Color(0.8, 0.7, 1.0))

		mesh.position.y = height + mesh_height * 0.5
		height += mesh_height
		stack_root.add_child(mesh)

func _mat(color: Color, transparent: bool = false) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	if transparent:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat

# ── Complétion ────────────────────────────────────────────────────────────────

func is_complete() -> bool:
	if stack.size() < 3:
		return false
	if stack.front() != ItemType.BUN:
		return false
	if stack.back() != ItemType.BUN:
		return false
	return ItemType.STEAK in stack
