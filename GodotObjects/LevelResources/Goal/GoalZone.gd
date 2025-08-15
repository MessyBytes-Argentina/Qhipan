extends Area3D

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(finish)

## On body_entered calls for the next level and blocks movement of the player
func finish(_body) -> void:
	LevelManager.next_level()
	body_entered.disconnect(finish)
	get_tree().call_group("InputBlocking","block_inputs")
