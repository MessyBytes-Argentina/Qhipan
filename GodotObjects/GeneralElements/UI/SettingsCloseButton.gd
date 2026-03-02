extends Button
const ANIMATION: Dictionary[String, Variant] = {
	"scale": 1.2,
	"time": 0.5,
	"ease": Tween.EaseType.EASE_OUT, 
	"trans": Tween.TransitionType.TRANS_BACK,
	"rotation": deg_to_rad(30)
}

## Name to close the popup window
@export var popupName: String = "Settings"
@export var pivotOffset: Vector2 = Vector2.ZERO

var tween: Tween
var progress: float = 0.0
var goalAngle: float
var canBeClosed: bool = false
var hadFocus: bool = false

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(_on_pressed)
	GeneralVariables.input_mode_changed.connect(set_controller_mode)
	set_controller_mode(GeneralVariables.usingGamepad)
	canBeClosed = false
	await get_tree().create_timer(0.5).timeout
	canBeClosed = true
	focus_entered.connect(_on_focus)
	mouse_entered.connect(_on_focus)
	focus_exited.connect(_on_focus_lost)
	mouse_exited.connect(_on_focus_lost)
	pivot_offset = size / 2.0 + pivotOffset

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
	hadFocus = false

func _animation_tick(currentProgress: float) -> void:
	progress = currentProgress
	rotation = lerp(0.0, goalAngle, progress)
	scale = Vector2.ONE * lerp(1.0, ANIMATION.scale, progress)

## When pressed unlocks the player controls and closes the window
func _on_pressed() -> void:
	rotation = goalAngle
	if not canBeClosed: return
	await get_tree().process_frame
	canBeClosed = false
	get_tree().call_group("Player", "set", "onSettings", false)
	PopupManager.close_popup_by_name(popupName)
	GeneralVariables.inventory.book.hide_book()

## Calls _on_pressed
func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("pause"): _on_pressed()

## Switches between mouse and controller for selection
func set_controller_mode(isController: bool) -> void:
	recursive_release_focus(get_parent().get_parent())
	if isController: grab_focus()

func recursive_release_focus(node: Node) -> void:
	if node is Button or node is TextureButton: node.release_focus()
	for child in node.get_children(): recursive_release_focus(child)
