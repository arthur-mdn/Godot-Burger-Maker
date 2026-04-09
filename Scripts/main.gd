extends Node3D

var held_item = null
var score := 0
var success_count := 0
var level_time_left := 0.0
var target_success := 0
var level_running := false

@onready var level_manager = $LevelManager
@onready var stations_root = $World/Stations
@onready var order_manager = $OrderManager
@onready var camera = $Camera3D

func _ready():
	var items = get_tree().get_nodes_in_group("item")
	for item in items:
		item.clicked.connect(_on_item_clicked)

	var dispensers = get_tree().get_nodes_in_group("dispenser")
	for d in dispensers:
		d.item_spawned.connect(_on_item_spawned)

	start_level()

func start_level():
	var level_data = level_manager.get_current_level()

	success_count = 0
	score = 0
	level_time_left = level_data["time_limit"]
	target_success = level_data["target_success"]
	level_running = true

	setup_level()

	order_manager.set_level_orders(level_data["allowed_orders"])
	order_manager.clear_orders()
	order_manager.start_orders(2)

	print("START LEVEL :", level_data["name"])
	print("Target success :", target_success)
	print("Time :", level_time_left)

func setup_level():
	var level_data = level_manager.get_current_level()
	var active_names = level_data["active_stations"]

	for station in stations_root.get_children():
		var enabled = station.name in active_names
		station.visible = enabled
		station.process_mode = Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED

		var body = station.find_child("StaticBody3D", true, false)
		if body:
			body.process_mode = Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED
			body.set_collision_layer_value(2, enabled)

func _input(event):
	if event is InputEventMouseButton and not event.pressed:
		if held_item != null:
			try_drop()

func _process(delta):
	if level_running:
		level_time_left -= delta

		if level_time_left <= 0:
			level_time_left = 0
			end_level(false)

	if held_item != null:
		var mouse_pos = get_viewport().get_mouse_position()
		var from = camera.project_ray_origin(mouse_pos)
		var to = from + camera.project_ray_normal(mouse_pos) * 1000
		var plane = Plane(Vector3.UP, 0)
		var hit = plane.intersects_ray(from, to)

		if hit:
			held_item.global_position = hit

func _on_item_clicked(clicked_item):
	if held_item != null:
		return

	if clicked_item.current_slot != null:
		clicked_item.current_slot.remove_item()

	held_item = clicked_item
	print("PICK :", clicked_item.name)

func _on_item_spawned(item):
	item.clicked.connect(_on_item_clicked)

	if held_item == null:
		held_item = item
	else:
		item.queue_free()

func try_drop():
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000

	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 2

	var result = space_state.intersect_ray(query)

	if result:
		var collider = result.collider
		var target = collider.get_parent()

		if target.has_method("place_item"):
			var placed = target.place_item(held_item)

			# serving station peut renvoyer true / false
			if placed == true:
				held_item = null
				return

			# si la station ne renvoie rien, on considère que ça a marché
			if placed == null:
				held_item = null
				return

	held_item = null

func register_success():
	success_count += 1
	score += 10

	print("SUCCESS COUNT :", success_count, "/", target_success)
	print("SCORE :", score)

	if success_count >= target_success:
		end_level(true)

func register_fail():
	score -= 5
	print("SCORE :", score)

func end_level(win: bool):
	if not level_running:
		return

	level_running = false

	if win:
		print("LEVEL COMPLETE")
	else:
		print("LEVEL FAILED")
