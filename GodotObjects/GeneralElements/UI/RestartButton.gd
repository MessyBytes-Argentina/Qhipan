extends Button

@export var levelList: Array[PackedScene]

func _ready() -> void:
	pressed.connect(restart)

func restart() -> void:
	LevelManager.change_to_id(0)
