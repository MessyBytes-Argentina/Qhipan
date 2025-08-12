extends Button

@export var levelList: Array[PackedScene]

func _ready() -> void:
	pressed.connect(next)

func next() -> void:
	LevelManager.next_level()
