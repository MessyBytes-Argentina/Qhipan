@tool
extends Button

## This [Button] holds animations and plays them on the procured events.
## Any animation dependencies must be added as childs of this scene (eg. [MultipleParticleEmitterControl])
class_name AnimatedButton

## This enum holds the possible pivot configs for the node.
enum PivotPositions {CENTER, TOP_LEFT, TOP, TOP_RIGHT, RIGHT, BOTTOM_RIGHT, BOTTOM, BOTTOM_LEFT, LEFT}
## The pivot config for the node.
@export var customPivotPosition: PivotPositions = PivotPositions.CENTER:
	set(value):
		customPivotPosition = value
		_relocate_pivot()
## The animations of this button.
@export_group("Animations")
## Reset animation. Highly recommended.
@export var resetAnimation: Animation
## Hover animation.
@export var hoverAnimation: Animation
## Click animation.
@export var clickAnimation: Animation
## Focus animation. Will play when you call [method set_focus]. Only one button will be in focus at a time.
@export var focusAnimation: Animation

## A reference to the created animation player.
var _animationPlayer: AnimationPlayer
## This bool indicates wether the button is currently being hovered or not.
var hovered: bool = false

## Signal to emit when the click animation is finished. Use this in place of [signal Button.pressed] if you want to wait until the animation is finished.
signal pressed_finished

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not Engine.is_editor_hint():
		mouse_entered.connect(_mouse_entered)
		mouse_exited.connect(_mouse_exited)
		if hoverAnimation or clickAnimation or focusAnimation or resetAnimation:
			_load_animations()
	add_to_group("AnimatedButtons")
	await get_tree().create_timer(0.1).timeout
	_relocate_pivot()

## Creates and loads the animation player with the provided animations.
func _load_animations() -> void:
	_animationPlayer = AnimationPlayer.new()
	var animationLibrary: AnimationLibrary = AnimationLibrary.new()
	if resetAnimation:
		animationLibrary.add_animation("RESET", resetAnimation)
	if hoverAnimation:
		animationLibrary.add_animation("hover", hoverAnimation)
	if clickAnimation:
		animationLibrary.add_animation("click", clickAnimation)
	if focusAnimation:
		animationLibrary.add_animation("focus", focusAnimation)
	_animationPlayer.add_animation_library("", animationLibrary)
	add_child(_animationPlayer)

## Sets the pivot to the set [param customPivotPosition].
func _relocate_pivot() -> void:
	match customPivotPosition:
		PivotPositions.CENTER:
			pivot_offset = size / 2
		PivotPositions.TOP_LEFT:
			pivot_offset = Vector2.ZERO
		PivotPositions.TOP:
			pivot_offset = Vector2(size.x / 2, 0)
		PivotPositions.TOP_RIGHT:
			pivot_offset = Vector2(size.x, 0)
		PivotPositions.RIGHT:
			pivot_offset = Vector2(size.x, size.y /2)
		PivotPositions.BOTTOM_RIGHT:
			pivot_offset = size
		PivotPositions.BOTTOM:
			pivot_offset = Vector2(size.x / 2, size.y)
		PivotPositions.BOTTOM_LEFT:
			pivot_offset = Vector2(0, size.y)
		PivotPositions.LEFT:
			pivot_offset = Vector2(0, size.y /2)

## Plays the hover sound for this button. Useful if needed for an animation.
func play_hover_sound() -> void:
	if is_in_group("SoundButtons"):
		ButtonSoundManager.play_sound("Hover", self)

## Plays the click animation.
func _pressed() -> void:
	_animationPlayer.play("RESET")
	await get_tree().create_timer(0.01).timeout
	if not _animationPlayer.animation_finished.is_connected(_click_finished):
		_animationPlayer.animation_finished.connect(_click_finished)
	_animationPlayer.play("click")

## Plays the hover animation.
func _mouse_entered() -> void:
	hovered = true
	if _animationPlayer.current_animation != "click":
		_animationPlayer.play("hover")

## Stops the hover animation.
func _mouse_exited() -> void:
	hovered = false
	if _animationPlayer.current_animation == "hover":
		await get_tree().create_timer(_animationPlayer.current_animation_length - _animationPlayer.current_animation_position).timeout
		if _animationPlayer.current_animation == "hover":
			_animationPlayer.stop()

## Emits [signal pressed_finished] and returns to hover animation if it's alooping animation.
func _click_finished(_animation_name: String) -> void:
	_animationPlayer.animation_finished.disconnect(_click_finished)
	pressed_finished.emit()
	if hoverAnimation.loop_mode != Animation.LOOP_NONE and hovered:
		_animationPlayer.play("hover")

## If true plays the focus animation and stops the focus animation on all other [AnimatedButton]s. If false stops the focus animation.
func set_focus(newFocus: bool) -> void:
	if newFocus:
		get_tree().call_group("AnimatedButtons", "set_focus", false)
		_animationPlayer.play("focus")
	else:
		if _animationPlayer.is_playing() and _animationPlayer.current_animation == "focus":
			_animationPlayer.stop()
