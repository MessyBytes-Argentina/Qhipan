extends Button

const ANIMATION: Dictionary[String, Variant] = {
	"scale": 1.1,
	"time": 0.5,
	"ease": Tween.EaseType.EASE_OUT, 
	"trans": Tween.TransitionType.TRANS_BACK,
	"rotation": deg_to_rad(5)
}
const playScreen: String = "uid://3iena3lvxxgn"
const TEXTS: Dictionary[String, String] = {
	"normal": "To Main Menu",
	"confirm": "Are you sure?"
}

## Name to close the popup window
@export var popupName: String = "Settings"
@export var pivotOffset: Vector2 = Vector2.ZERO

var tween: Tween
var progress: float = 0.0
var goalAngle: float
var canBeClosed: bool = false
var checking: bool = false
var hadFocus: bool = false

@onready var label: Label = %MainMenuLabel

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GeneralVariables.input_mode_changed.connect(set_controller_mode)
	GeneralVariables.new_gamestate.connect(_on_new_gamestate)
	visible = GeneralVariables.inGame
	set_controller_mode(GeneralVariables.usingGamepad)
	pressed.connect(_on_pressed)
	canBeClosed = false
	await get_tree().create_timer(0.5).timeout
	canBeClosed = true
	focus_entered.connect(_on_focus)
	mouse_entered.connect(_on_focus)
	focus_exited.connect(_on_focus_lost)
	mouse_exited.connect(_on_focus_lost)
	pivot_offset = size / 2.0 + pivotOffset

## Switches between mouse and controller for selection
func set_controller_mode(isController: bool) -> void:
	if isController: grab_focus()
	else: release_focus()

## Calls the LevelManager to load the first level of the current list
func restart() -> void:
	GeneralVariables.sceneManager.shaderColorRect.color = Color.BLACK
	GeneralVariables.sceneManager.load_and_switch(playScreen)

func _on_focus() -> void:
	if hadFocus: return
	if tween: if tween.is_running(): tween.kill()
	tween = create_tween()
	var time: float = ANIMATION.time * (1.0 - progress)
	goalAngle = [-1, 1].pick_random() * ANIMATION.rotation
	tween.tween_method(_animation_tick, progress, 1.0, time).set_ease(ANIMATION.ease as Tween.EaseType). set_trans(ANIMATION.trans as Tween.TransitionType)
	tween.play()
	hadFocus = true

func _on_focus_lost() -> void:
	if tween: if tween.is_running(): tween.kill()
	tween = create_tween()
	var time: float = ANIMATION.time * progress
	tween.tween_method(_animation_tick, progress, 0.0, time).set_ease(ANIMATION.ease as Tween.EaseType). set_trans(ANIMATION.trans as Tween.TransitionType)
	tween.play()
	checking = false
	label.text = TEXTS.normal
	hadFocus = false

func _animation_tick(currentProgress: float) -> void:
	progress = currentProgress
	rotation = lerp(0.0, goalAngle, progress)
	scale = Vector2.ONE * lerp(1.0, ANIMATION.scale, progress)

## When pressed unlocks the player controls and closes the window
func _on_pressed() -> void:
	rotation = goalAngle
	if not checking:
		checking = true
		label.text = TEXTS.confirm
		return
	PopupManager.close_popup_by_name(popupName)
	GeneralVariables.inventory.book.hide_book(true)
	restart()
	label.text = TEXTS.normal

func _on_new_gamestate(isPlaying: bool) -> void:
	set_deferred("visible", isPlaying)
