extends Node3D

enum ItemType { BUN, STEAK, CHEESE, TOMATO, SALAD, ONION }
enum CookState { NONE, RAW, COOKING, COOKED, BURNT }

const CHOPPABLE_TYPES := [ItemType.TOMATO, ItemType.ONION, ItemType.SALAD]

@export var type: ItemType

signal clicked(item)

@onready var stack_root = $Visual/StackRoot
@onready var area = $Area3D

const BUN_BOTTOM_SCENE := preload("res://Assets/KayKit/gltf/food_ingredient_bun_bottom.gltf")
const BUN_TOP_SCENE := preload("res://Assets/KayKit/gltf/food_ingredient_bun_top.gltf")
const STEAK_RAW_SCENE := preload("res://Assets/KayKit/gltf/food_ingredient_burger_uncooked.gltf")
const STEAK_COOKED_SCENE := preload("res://Assets/KayKit/gltf/food_ingredient_burger_cooked.gltf")
const STEAK_BURNT_SCENE := preload("res://Assets/KayKit/gltf/food_ingredient_burger_trash.gltf")
const CHEESE_SLICE_SCENE := preload("res://Assets/KayKit/gltf/food_ingredient_cheese_slice.gltf")
const TOMATO_WHOLE_SCENE := preload("res://Assets/KayKit/gltf/food_ingredient_tomato.gltf")
const TOMATO_SLICES_SCENE := preload("res://Assets/KayKit/gltf/food_ingredient_tomato_slices.gltf")
const TOMATO_SLICE_SCENE := preload("res://Assets/KayKit/gltf/food_ingredient_tomato_slice.gltf")
const KAYKIT_BUN_SCALE := 1.45
const KAYKIT_BUN_BOTTOM_HEIGHT := 0.29
const KAYKIT_BUN_TOP_HEIGHT := 0.45
const KAYKIT_PATTY_SCALE := 1.2
const KAYKIT_PATTY_HEIGHT := 0.24
const KAYKIT_CHEESE_SCALE := 1.15
const KAYKIT_CHEESE_HEIGHT := 0.12
const KAYKIT_TOMATO_SCALE := 0.95
const KAYKIT_TOMATO_SLICES_SCALE := 1.0
const KAYKIT_TOMATO_SLICE_SCALE := 1.1

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

func type_needs_chopping(t: ItemType) -> bool:
	return t in CHOPPABLE_TYPES


func _is_ready_to_use(item) -> bool:
	match item.type:
		ItemType.STEAK:
			return item.cook_state == CookState.COOKED
		ItemType.TOMATO, ItemType.ONION, ItemType.SALAD:
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

func _mesh_height_for(t: int, stack_index: int = -1) -> float:
	match t:
		ItemType.BUN:
			if stack_index >= 0 and _bun_count() == 2 and _bun_index_at(stack_index) == 1:
				return KAYKIT_BUN_TOP_HEIGHT
			return KAYKIT_BUN_BOTTOM_HEIGHT
		ItemType.STEAK:  return KAYKIT_PATTY_HEIGHT
		ItemType.CHEESE: return KAYKIT_CHEESE_HEIGHT
		ItemType.TOMATO: return 0.06 if is_chopped else 0.12
		ItemType.SALAD:  return 0.08 if is_chopped else 0.15
		ItemType.ONION:  return 0.04 if is_chopped else 0.08
		_: return 0.1


func _bun_index_at(stack_index: int) -> int:
	var count := 0
	for j in range(stack_index):
		if stack[j] == ItemType.BUN:
			count += 1
	return count


func rebuild_visual():
	for child in stack_root.get_children():
		child.free()

	stack_root.position = Vector3.ZERO

	var stack_top := 0.0
	var has_top_bun := (_bun_count() == 2)

	for i in range(stack.size()):
		var t = stack[i]
		var mesh_height := _mesh_height_for(t, i)

		if t == ItemType.BUN:
			var is_top_bun := has_top_bun and _bun_index_at(i) == 1
			stack_top = _stack_place_model(_create_bun_visual(is_top_bun), stack_top)
			continue

		if t == ItemType.STEAK:
			var steak_state: CookState = visual_cook_state if type == ItemType.STEAK else steak_visual_state
			stack_top = _stack_place_model(_create_steak_visual(steak_state), stack_top)
			continue

		if t == ItemType.CHEESE:
			stack_top = _stack_place_model(_create_cheese_visual(), stack_top)
			continue

		if t == ItemType.TOMATO:
			var in_burger_stack := stack.size() > 1
			stack_top = _stack_place_model(_create_tomato_visual(in_burger_stack), stack_top)
			continue

		if t == ItemType.SALAD:
			var in_burger_stack := stack.size() > 1
			stack_top = _stack_place_model(_create_salad_visual(in_burger_stack), stack_top)
			continue

		var mesh = MeshInstance3D.new()

		match t:
			ItemType.ONION:
				mesh.mesh = BoxMesh.new()
				mesh.scale = Vector3(0.9, mesh_height, 0.9)
				mesh.material_override = _mat(Color(0.95, 0.85, 1.0) if is_chopped else Color(0.8, 0.7, 1.0))

		mesh.position.y = stack_top + mesh_height * 0.5
		stack_top += mesh_height
		stack_root.add_child(mesh)


func _stack_place_model(model: Node3D, stack_top: float) -> float:
	stack_root.add_child(model)
	var aabb := _combined_mesh_aabb(model)
	if aabb.size.length_squared() < 0.000001:
		model.position.y = stack_top
		return stack_top + 0.1
	model.position.y = stack_top - aabb.position.y
	return stack_top + aabb.size.y


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


func _create_bun_visual(is_top: bool) -> Node3D:
	var model: Node3D = (BUN_TOP_SCENE if is_top else BUN_BOTTOM_SCENE).instantiate()
	model.scale = Vector3.ONE * KAYKIT_BUN_SCALE
	if is_top:
		_set_model_transparent(model, 0.4)
	return model


func _create_cheese_visual() -> Node3D:
	var model: Node3D = CHEESE_SLICE_SCENE.instantiate()
	model.scale = Vector3.ONE * KAYKIT_CHEESE_SCALE
	return model


func _create_salad_visual(in_burger_stack: bool) -> Node3D:
	var prepared := is_chopped or in_burger_stack
	var mesh := MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	var height := 0.08 if prepared else 0.15
	mesh.scale = Vector3(0.9 if prepared else 1.0, height, 0.9 if prepared else 1.0)
	mesh.material_override = _mat(Color(0.35, 0.9, 0.35) if prepared else Color(0.15, 0.65, 0.15))
	return mesh


func _create_tomato_visual(in_burger_stack: bool) -> Node3D:
	var model: Node3D
	if in_burger_stack:
		model = TOMATO_SLICE_SCENE.instantiate()
		model.scale = Vector3.ONE * KAYKIT_TOMATO_SLICE_SCALE
	elif is_chopped:
		model = TOMATO_SLICES_SCENE.instantiate()
		model.scale = Vector3.ONE * KAYKIT_TOMATO_SLICES_SCALE
	else:
		model = TOMATO_WHOLE_SCENE.instantiate()
		model.scale = Vector3.ONE * KAYKIT_TOMATO_SCALE
	return model


func _create_steak_visual(state: CookState) -> Node3D:
	var scene: PackedScene

	match state:
		CookState.RAW, CookState.COOKING:
			scene = STEAK_RAW_SCENE
		CookState.COOKED:
			scene = STEAK_COOKED_SCENE
		CookState.BURNT:
			scene = STEAK_BURNT_SCENE
		_:
			scene = STEAK_RAW_SCENE

	var model: Node3D = scene.instantiate()
	model.scale = Vector3.ONE * KAYKIT_PATTY_SCALE

	if state == CookState.COOKING:
		_set_model_modulate(model, Color(1.0, 0.88, 0.72))

	return model


func _set_model_modulate(root: Node3D, tint: Color) -> void:
	for mesh_instance in root.find_children("*", "MeshInstance3D", true, false):
		if mesh_instance.mesh == null:
			continue
		for surface_idx in range(mesh_instance.mesh.get_surface_count()):
			var mat = mesh_instance.get_active_material(surface_idx)
			if mat == null:
				continue
			var dup = mat.duplicate()
			if dup is StandardMaterial3D:
				dup.albedo_color *= tint
			mesh_instance.set_surface_override_material(surface_idx, dup)


func _set_model_transparent(root: Node3D, alpha: float) -> void:
	for mesh_instance in root.find_children("*", "MeshInstance3D", true, false):
		if mesh_instance.mesh == null:
			continue
		for surface_idx in range(mesh_instance.mesh.get_surface_count()):
			var mat = mesh_instance.get_active_material(surface_idx)
			if mat == null:
				continue
			var dup = mat.duplicate()
			if dup is StandardMaterial3D:
				dup.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				dup.albedo_color.a = alpha
				dup.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
				dup.render_priority = 1
			mesh_instance.set_surface_override_material(surface_idx, dup)

func _mat(color: Color, transparent: bool = false) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	if transparent:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		mat.render_priority = 1  # rendu après tous les meshes opaques
		mat.cull_mode = BaseMaterial3D.CULL_BACK
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
