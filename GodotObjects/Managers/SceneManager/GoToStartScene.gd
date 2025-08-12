extends Control

const startScenePath: String = "uid://3iena3lvxxgn"

func go_to_start_scene() -> void:
	await get_tree().create_timer(1).timeout
	LevelManager.change_level_to_path(startScenePath)
