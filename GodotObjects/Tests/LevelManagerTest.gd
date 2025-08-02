extends Node

@export var levelList: Array[PackedScene]

func _ready() -> void:
	LevelManager.set_list(levelList)
