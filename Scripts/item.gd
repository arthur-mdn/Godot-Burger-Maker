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

# Stocke le visual_cook_state du steak mergé pour pouvoir le restituer
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

	# Récupère le visual_cook_state du steak avant queue_free
	if t == ItemType.STEAK:
		steak_visual_state = other.visual_cook_state

	var insert_idx: int
	match t:
		ItemType.BUN:
			if _bun_count() == 0:
				insert_idx = 0
			else:
				insert_idx = stack.size()
		ItemType.STEAK:
			if stack.size() > 0 and stack[0] == ItemType.BUN:
				insert_idx = 1
			else:
				insert_idx = 0
		_:
			if stack.size() > 0 and stack.back() == ItemType.BUN:
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

func rebuild_visual():
	for child in stack_root.get_children():
		child.queue_free()

	var height = 0.0

	for t in stack:
		var mesh = MeshInstance3D.new()

		match t:
			ItemType.BUN:
				mesh.mesh = BoxMesh.new()
				mesh.scale = Vector3(1, 0.3, 1)
				mesh.material_override = _mat(Color(0.8, 0.6, 0.3))

			ItemType.STEAK:
				mesh.mesh = BoxMesh.new()
				mesh.scale = Vector3(0.9, 0.2, 0.9)
				# Utilise steak_visual_state : valide que le steak soit standalone ou mergé
				var s = visual_cook_state if type == ItemType.STEAK else steak_visual_state
				match s:
					CookState.RAW:     mesh.material_override = _mat(Color(1.0, 0.3, 0.3))
					CookState.COOKING: mesh.material_override = _mat(Color(0.9, 0.25, 0.05))
					CookState.COOKED:  mesh.material_override = _mat(Color(0.4, 0.2, 0.1))
					CookState.BURNT:   mesh.material_override = _mat(Color(0.1, 0.1, 0.1))
					_:                 mesh.material_override = _mat(Color(0.4, 0.2, 0.1))

			ItemType.CHEESE:
				mesh.mesh = BoxMesh.new()
				mesh.scale = Vector3(0.9, 0.1, 0.9)
				mesh.material_override = _mat(Color(1.0, 0.8, 0.2))

			ItemType.TOMATO:
				mesh.mesh = BoxMesh.new()
				mesh.scale = Vector3(0.9, 0.06 if is_chopped else 0.12, 0.9)
				mesh.material_override = _mat(Color(1.0, 0.1, 0.1) if is_chopped else Color(1.0, 0.2, 0.2))

			ItemType.SALAD:
				mesh.mesh = BoxMesh.new()
				mesh.scale = Vector3(0.9, 0.15, 0.9)
				mesh.material_override = _mat(Color(0.2, 0.8, 0.2))

			ItemType.ONION:
				mesh.mesh = BoxMesh.new()
				mesh.scale = Vector3(0.9, 0.04 if is_chopped else 0.08, 0.9)
				mesh.material_override = _mat(Color(0.95, 0.85, 1.0) if is_chopped else Color(0.8, 0.7, 1.0))

		mesh.position.y = height
		height += mesh.scale.y
		stack_root.add_child(mesh)

func _mat(color: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
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
