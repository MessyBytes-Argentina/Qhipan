extends Area3D

func _ready() -> void:
	body_entered.connect(return_player)

func return_player(_body) -> void:
	get_tree().call_group("Player", "restart_at_checkpoint")
