extends Node3D

var held_item = null

@onready var camera = $Camera3D

func _ready():
	# Connexion des items déjà présents dans la scène
	var items = get_tree().get_nodes_in_group("item")
	for item in items:
		item.clicked.connect(_on_item_clicked)

	# Connexion des dispensers
	var dispensers = get_tree().get_nodes_in_group("dispenser")
	for d in dispensers:
		d.item_spawned.connect(_on_item_spawned)

func _input(event):
	if event is InputEventMouseButton and not event.pressed:
		if held_item != null:
			try_drop()

func _process(_delta):
	if held_item != null:
		var mouse_pos = get_viewport().get_mouse_position()
		var from = camera.project_ray_origin(mouse_pos)
		var to = from + camera.project_ray_normal(mouse_pos) * 1000
		var plane = Plane(Vector3.UP, 0)
		var hit = plane.intersects_ray(from, to)
		if hit:
			held_item.global_position = hit

func _on_item_clicked(clicked_item):
	# Mains déjà pleines → on ignore
	if held_item != null:
		return
	if clicked_item.current_slot != null:
		clicked_item.current_slot.remove_item()
	held_item = clicked_item
	print("PICK :", clicked_item.name)

func _on_item_spawned(item):
	# Connecte le signal de click du nouvel item
	item.clicked.connect(_on_item_clicked)
	# Si les mains sont libres, on prend l'item
	if held_item == null:
		held_item = item
	else:
		# Mains pleines : annule le spawn
		item.queue_free()

func try_drop():
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000

	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)

	if result:
		var collider = result.collider
		if collider.get_parent().has_method("place_item"):
			var target = collider.get_parent()
			var placed = target.place_item(held_item)
			if placed:
				held_item = null
			# Sinon → merge invalide ou slot plein, on garde l'item en main
			return

	# Relâché dans le vide → on lâche l'item sur le sol
	held_item = null
