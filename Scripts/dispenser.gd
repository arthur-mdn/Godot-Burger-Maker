extends Node3D

## Type d'item dispensé (valeur de l'enum ItemType dans item.gd)
## 0=BUN, 1=STEAK, 2=CHEESE, 3=TOMATO, 4=SALAD, 5=ONION
@export var item_type: int = 0

const ItemScene = preload("res://Scenes/Item.tscn")

@onready var area = $Area3D

signal item_spawned(item)


func _ready():
	add_to_group("dispenser")
	area.input_event.connect(_on_input_event)


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
