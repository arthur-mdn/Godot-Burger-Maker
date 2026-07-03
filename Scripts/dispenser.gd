extends Node3D

## Type d'item dispensé (valeur de l'enum ItemType dans item.gd)
## 0=BUN, 1=STEAK, 2=CHEESE, 3=TOMATO, 4=SALAD, 5=ONION
@export var item_type: int = 0

const ItemScene = preload("res://Scenes/Item.tscn")

const KAYKIT_VISUALS := {
	0: preload("res://Assets/KayKit/gltf/crate_buns.gltf"),
	1: preload("res://Assets/KayKit/gltf/crate_steak.gltf"),
	2: preload("res://Assets/KayKit/gltf/crate_cheese.gltf"),
	3: preload("res://Assets/KayKit/gltf/crate_tomatoes.gltf"),
}

const FALLBACK_COLORS := {
	0: Color(0.8, 0.6, 0.3),
	1: Color(1.0, 0.3, 0.3),
	2: Color(1.0, 0.8, 0.2),
	3: Color(1.0, 0.2, 0.2),
	4: Color(0.2, 0.8, 0.2),
	5: Color(0.8, 0.7, 1.0),
}

@onready var area = $Area3D
@onready var visual_root = $Visual

signal item_spawned(item)


func _ready():
	add_to_group("dispenser")
	area.input_event.connect(_on_input_event)
	_update_visual()


func _on_input_event(_camera, event, _position, _normal, _shape_idx):
	if event is InputEventMouseButton \
	and event.pressed \
	and event.button_index == MOUSE_BUTTON_LEFT:
		_dispense()


func _dispense():
	var item = ItemScene.instantiate()
	item.type = item_type
	get_parent().add_child(item)
	item.global_position = global_position + Vector3(0, 1.0, 0)
	emit_signal("item_spawned", item)


func _update_visual():
	for child in visual_root.get_children():
		child.queue_free()

	if KAYKIT_VISUALS.has(item_type):
		var model: Node3D = KAYKIT_VISUALS[item_type].instantiate()
		visual_root.add_child(model)
		match item_type:
			0, 1, 2, 3:
				model.scale = Vector3(0.55, 0.55, 0.55)
		return

	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.2, 1, 1.2)
	mesh_instance.mesh = box
	mesh_instance.position = Vector3(0, 0.5, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = FALLBACK_COLORS.get(item_type, Color.GRAY)
	mesh_instance.material_override = mat
	visual_root.add_child(mesh_instance)
