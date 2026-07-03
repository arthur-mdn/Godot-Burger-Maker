extends Node

const SAVE_PATH := "user://save_data.json"
const MAIN_SCENE := "res://Scenes/main.tscn"
const MENU_SCENE := "res://Scenes/MainMenu.tscn"
const LEVEL_SELECT_SCENE := "res://Scenes/LevelSelect.tscn"

var unlocked_level_count := 1
var best_scores: Dictionary = {}


func _ready() -> void:
	load_progress()


func is_level_unlocked(index: int) -> bool:
	return index < unlocked_level_count


func get_best_score(index: int) -> int:
	return best_scores.get(index, 0)


func unlock_after_level(completed_index: int) -> void:
	var next_count := completed_index + 2
	if next_count > unlocked_level_count:
		unlocked_level_count = mini(next_count, LevelManager.get_level_count())
		save_progress()


func update_best_score(level_index: int, score: int) -> void:
	var current := get_best_score(level_index)
	if score > current:
		best_scores[level_index] = score
		save_progress()


func start_level(level_index: int) -> void:
	LevelManager.set_current_level(level_index)
	get_tree().change_scene_to_file(MAIN_SCENE)


func go_to_menu() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)


func go_to_level_select() -> void:
	get_tree().change_scene_to_file(LEVEL_SELECT_SCENE)


func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return

	unlocked_level_count = parsed.get("unlocked_level_count", 1)
	best_scores = parsed.get("best_scores", {})


func save_progress() -> void:
	var data := {
		"unlocked_level_count": unlocked_level_count,
		"best_scores": best_scores
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return

	file.store_string(JSON.stringify(data))
