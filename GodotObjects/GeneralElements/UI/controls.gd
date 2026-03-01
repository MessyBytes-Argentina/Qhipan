extends MarginContainer

## Reference to the keyboard controller container.
@onready var keyboardControls: VBoxContainer = %KeyboardControls
## Reference to the gamepad controller container.
@onready var gamepadControls: VBoxContainer = %GamepadControls

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GeneralVariables.input_mode_changed.connect(set_controller)
	set_controller(GeneralVariables.usingGamepad)

## Hides and shows correct control scheme.
func set_controller(isGamepad: bool) -> void:
	keyboardControls.set_deferred("visible", not isGamepad)
	gamepadControls.set_deferred("visible", isGamepad)
