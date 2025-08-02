extends Button

@export var levelList: Array[PackedScene]

func _ready() -> void:
	pressed.connect(start)

func start() -> void:
	LevelManager.set_list(levelList)
