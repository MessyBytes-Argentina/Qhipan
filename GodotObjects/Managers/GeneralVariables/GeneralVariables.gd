extends Node

signal input_mode_changed(isGamepad: bool)

const MOUSEMOVEMENTTHRESHOLD: float = 15

var usingGamepad: bool = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion: if event.relative.length() < MOUSEMOVEMENTTHRESHOLD: return
	var currentlyGamepad: bool = event is InputEventJoypadButton or event is InputEventJoypadMotion
	if usingGamepad != currentlyGamepad:
		usingGamepad = currentlyGamepad
		input_mode_changed.emit(usingGamepad)
