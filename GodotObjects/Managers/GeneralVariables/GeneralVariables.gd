extends Node

signal input_mode_changed(isGamepad: bool)

var usingGamepad: bool = false

func _input(event: InputEvent) -> void:
	var currentlyGamepad: bool = event is InputEventJoypadButton or event is InputEventJoypadMotion
	if usingGamepad != currentlyGamepad:
		usingGamepad = currentlyGamepad
		input_mode_changed.emit(usingGamepad)
