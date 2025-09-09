extends Area3D

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(return_player)

## On body_entered calls restart_at_checkpoint on the Player
func return_player(_body) -> void:
	get_tree().call_group("Player", "restart_at_checkpoint")
