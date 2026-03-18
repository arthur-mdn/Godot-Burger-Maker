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

func _ready():
	add_to_group("item")
	area.input_event.connect(_on_input_event)
	stack.append(type)
	if type == ItemType.STEAK:
		cook_state = CookState.RAW
		visual_cook_state = CookState.RAW
	rebuild_visual()

func _on_input_event(_camera, event, _position, _normal, _shape_idx):
	if event is InputEventMouseButton \
	and event.pressed \
	and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("clicked", self)

func can_merge(other) -> bool:
	# Un burger complet ne peut plus recevoir d'ingrédient
	if is_complete():
		return false

	var last = stack.back()

	match last:
		ItemType.BUN:
			# BUN du bas (seul) → accepte uniquement un steak cuit
			if stack.size() == 1:
				return other.type == ItemType.STEAK and other.cook_state == CookState.COOKED
			# BUN de fermeture → rien à ajouter
			return false

		ItemType.STEAK:
			# Après le steak : toppings ou BUN de fermeture, pas de second steak
			return other.type != ItemType.STEAK

		ItemType.CHEESE, ItemType.TOMATO, ItemType.SALAD, ItemType.ONION:
			# Après un topping : autre topping ou BUN de fermeture, pas de steak
			return other.type != ItemType.STEAK

	return false

func merge(other):
	for t in other.stack:
		stack.append(t)
	other.queue_free()
	rebuild_visual()
	print("STACK :", stack)
	if is_complete():
		print("✅ BURGER COMPLET !")

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
				match visual_cook_state:
					CookState.RAW:     mesh.material_override = _mat(Color(1.0, 0.3, 0.3))
					CookState.COOKING: mesh.material_override = _mat(Color(0.9, 0.25, 0.05)) # orange
					CookState.COOKED:  mesh.material_override = _mat(Color(0.4, 0.2, 0.1))
					CookState.BURNT:   mesh.material_override = _mat(Color(0.1, 0.1, 0.1))

			ItemType.CHEESE:
				mesh.mesh = BoxMesh.new()
				mesh.scale = Vector3(0.9, 0.1, 0.9)
				mesh.material_override = _mat(Color(1.0, 0.8, 0.2))

			ItemType.TOMATO:
				mesh.mesh = BoxMesh.new()
				mesh.scale = Vector3(0.9, 0.1, 0.9)
				mesh.material_override = _mat(Color(1.0, 0.2, 0.2))

			ItemType.SALAD:
				mesh.mesh = BoxMesh.new()
				mesh.scale = Vector3(0.9, 0.15, 0.9)
				mesh.material_override = _mat(Color(0.2, 0.8, 0.2))

			ItemType.ONION:
				mesh.mesh = BoxMesh.new()
				mesh.scale = Vector3(0.9, 0.08, 0.9)
				mesh.material_override = _mat(Color(0.8, 0.7, 1.0))

		mesh.position.y = height
		height += mesh.scale.y
		stack_root.add_child(mesh)

func _mat(color: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	return mat

func is_complete() -> bool:
	if stack.size() < 3:
		return false
	if stack.front() != ItemType.BUN:
		return false
	if stack.back() != ItemType.BUN:
		return false
	return ItemType.STEAK in stack
