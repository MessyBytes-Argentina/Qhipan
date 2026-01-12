extends Button

## Name to close the popup window
@export var popupName: String = "Settings"

var canBeClosed: bool = false

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(_on_pressed)
	canBeClosed = false
	await get_tree().create_timer(0.5).timeout
	canBeClosed = true

## When pressed unlocks the player controls and closes the window
func _on_pressed() -> void:
	if not canBeClosed: return
	await get_tree().process_frame
	canBeClosed = false
	get_tree().call_group("Player", "set", "onSettings", false)
	PopupManager.close_popup_by_name(popupName)
	GeneralVariables.inventory.book.hide_book()

## Calls _on_pressed
func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("pause"): _on_pressed()
