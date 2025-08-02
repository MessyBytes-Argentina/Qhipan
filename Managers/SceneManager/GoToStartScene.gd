extends Control

@export var startScenePath: String

func go_to_start_scene() -> void:
	LevelManager.change_level(startScenePath)
