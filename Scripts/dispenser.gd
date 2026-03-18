extends Node3D

## Type d'item dispensé (valeur de l'enum ItemType dans item.gd)
## 0=BUN, 1=STEAK, 2=CHEESE, 3=TOMATO, 4=SALAD, 5=ONION
@export var item_type: int = 0

const ItemScene = preload("res://Scenes/Item.tscn")

@onready var area = $Area3D
@onready var mesh_instance = $MeshInstance3D

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
	# Ajout dans le parent de la scène principale
	get_parent().add_child(item)
	item.global_position = global_position + Vector3(0, 1.2, 0)
	emit_signal("item_spawned", item)

func _update_visual():
	if not is_instance_valid(mesh_instance):
		return
	var mat = StandardMaterial3D.new()
	match item_type:
		0: mat.albedo_color = Color(0.8, 0.6, 0.3)  # BUN
		1: mat.albedo_color = Color(1.0, 0.3, 0.3)  # STEAK
		2: mat.albedo_color = Color(1.0, 0.8, 0.2)  # CHEESE
		3: mat.albedo_color = Color(1.0, 0.2, 0.2)  # TOMATO
		4: mat.albedo_color = Color(0.2, 0.8, 0.2)  # SALAD
		5: mat.albedo_color = Color(0.8, 0.7, 1.0)  # ONION
	mesh_instance.material_override = mat
