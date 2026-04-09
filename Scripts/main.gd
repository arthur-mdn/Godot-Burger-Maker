extends Node3D

var held_item = null
var score := 0
var fail_count := 0
var success_count := 0
var level_time_left := 0.0
var target_success := 0
var max_failures := 3
var level_running := false

@onready var level_manager = $LevelManager
@onready var stations_root = $World/Stations
@onready var order_manager = $OrderManager
@onready var camera = $Camera3D

@onready var score_label = $CanvasLayer/ScoreLabel
@onready var timer_label = $CanvasLayer/TimerLabel
@onready var success_label = $CanvasLayer/SuccessLabel
@onready var fail_label = $CanvasLayer/FailLabel

func _ready():
	var items = get_tree().get_nodes_in_group("item")
	for item in items:
		item.clicked.connect(_on_item_clicked)

	var dispensers = get_tree().get_nodes_in_group("dispenser")
	for d in dispensers:
		d.item_spawned.connect(_on_item_spawned)

	order_manager.order_expired.connect(_on_order_expired)
	
	start_level()

func start_level():
	var level_data = level_manager.get_current_level()

	success_count = 0
	fail_count = 0
	score = 0
	level_time_left = level_data["time_limit"]
	target_success = level_data["target_success"]
	max_failures = level_data["max_failures"]
	level_running = true

	setup_level()

	order_manager.set_level_orders(level_data["allowed_orders"])
	order_manager.clear_orders()
	order_manager.start_orders(2)

	update_level_ui()

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

func update_level_ui():
	if score_label:
		score_label.text = "Score : " + str(score)

	if timer_label:
		timer_label.text = "Temps : " + str(int(ceil(level_time_left))) + "s"

	if success_label:
		success_label.text = "Succès : " + str(success_count) + " / " + str(target_success)

	if fail_label:
		fail_label.text = "Erreurs : " + str(fail_count) + " / " + str(max_failures)

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
		update_level_ui()

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

	update_level_ui()

	print("SUCCESS COUNT :", success_count, "/", target_success)
	print("SCORE :", score)

	if success_count >= target_success:
		end_level(true)

func register_fail():
	fail_count += 1
	score -= 5

	update_level_ui()

	print("FAIL COUNT :", fail_count, "/", max_failures)
	print("SCORE :", score)

	if fail_count >= max_failures:
		end_level(false)

func _on_order_expired():
	register_fail()

func end_level(win: bool):
	if not level_running:
		return

	level_running = false
	update_level_ui()

	if win:
		print("LEVEL COMPLETE")
	else:
		print("LEVEL FAILED")
