extends Node3D

var held_item = null

@onready var camera = $Camera3D

func _ready():
	var items = get_tree().get_nodes_in_group("item")

	for item in items:
		item.clicked.connect(_on_item_clicked)

func _input(event):
	if event is InputEventMouseButton and not event.pressed:
		if held_item != null:
			try_drop()

func _process(delta):
	if held_item != null:
		var mouse_pos = get_viewport().get_mouse_position()

		var from = camera.project_ray_origin(mouse_pos)
		var to = from + camera.project_ray_normal(mouse_pos) * 1000

		var plane = Plane(Vector3.UP, 0) # sol à Y = 0
		var hit = plane.intersects_ray(from, to)

		if hit:
			held_item.global_position = hit

func _on_item_clicked(clicked_item):
	# libère le slot proprement
	if clicked_item.current_slot != null:
		clicked_item.current_slot.remove_item()

	held_item = clicked_item
	print("PICK :", clicked_item.name)

func try_drop():
	var mouse_pos = get_viewport().get_mouse_position()

	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000

	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)

	var result = space_state.intersect_ray(query)

	if result:
		var collider = result.collider

		# si c'est un slot
		if collider.get_parent().has_method("place_item"):
			var slot = collider.get_parent()
			print("TRY PLACE")
			slot.place_item(held_item)

	held_item = null
