extends Button

## Name to close the popup window
@export var popupName: String = "Settings"

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(_on_pressed)

## When pressed unlocks the player controls and closes the window
func _on_pressed() -> void:
	get_tree().call_group("Player", "set", "onSettings", false)
	PopupManager.close_popup_by_name(popupName)

## Calls _on_pressed
func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("pause"): _on_pressed()
