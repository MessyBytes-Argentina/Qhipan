extends Button

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	var restartEvent: InputEventAction = InputEventAction.new()
	restartEvent.action = "reset_scene"
	restartEvent.pressed = true
	Input.parse_input_event(restartEvent)
