extends Button

@export var levelList: Array[String]

func _ready() -> void:
	pressed.connect(start)

func start() -> void:
	LevelManager.set_list(levelList)
