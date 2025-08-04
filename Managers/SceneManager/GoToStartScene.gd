extends Control

@export var startScenePath: String

func go_to_start_scene() -> void:
	await get_tree().create_timer(1).timeout
	LevelManager.change_level(startScenePath)
