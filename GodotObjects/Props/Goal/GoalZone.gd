extends Area3D


func _ready() -> void:
	body_entered.connect(finish)

func finish(_body) -> void:
	LevelManager.next_level()
	body_entered.disconnect(finish)
