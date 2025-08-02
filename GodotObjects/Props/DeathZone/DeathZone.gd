extends Area3D

func _ready() -> void:
	body_entered.connect(return_player)

func return_player(_body) -> void:
	var restartEvent: InputEventAction = InputEventAction.new()
	restartEvent.action = "reset_player"
	restartEvent.pressed = true
	Input.parse_input_event(restartEvent)
