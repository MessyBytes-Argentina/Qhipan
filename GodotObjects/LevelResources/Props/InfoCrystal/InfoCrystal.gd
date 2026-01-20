extends Area3D

## Length of bobbing in the y axis.
const BOBBINGHEIGHT: float = 0.1
## Amount of time the bobbing animation takes.
const BOBBINGTIME: float = 3.0
## Amount of time it takes the crystal to rotate.
const ROTATIONTIME: float = 5.0
## Amount of time it takes the pop up to show up and disappear.
const POPUPTIME: float = 0.4
## Amount of time it takes the info icon to show up and disappear.
const INFOSHRINKTIME: float = 0.1
## Amount of time it takes the info icon or pop up to show up and disappear when zooming out.
const HIDESHOWZOOMTIME: float = 0.2

## Tutorial sprite to show for keyboard.
@export var infoSpriteKeyboard: Texture2D
## Tutorial sprite to show for controller.
@export var infoSpriteController: Texture2D

## Crystal mesh reference.
@onready var crystal: MeshInstance3D = $Crystal
## Info icon sprite reference.
@onready var infoIcon: Sprite3D = %InfoIcon
## Pop up board sprite reference.
@onready var popupBoard: Sprite3D = %PopupBoard
## Pop up sound player reference .
@onready var popUpSound: RandomSoundPlayer = %PopUpSound

## Tween for th rotation animation.
var rotationTween: Tween
## Tween for the bobbing animation.
var bobbingTween: Tween
## Tween for the popup animation.
var popupTween: Tween
## Player reference to show and hide the popup.
var player: Player
## Flag that stops the animation from playing multiple times.
var poppedUp: bool = false

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_bobbing()
	body_entered.connect(do_popup.unbind(1))
	body_exited.connect(do_popout.unbind(1))
	change_input(GeneralVariables.usingGamepad)
	while not player:
		player = get_tree().get_first_node_in_group("Player")
		await get_tree().process_frame
	player.zooming_out.connect(zooming_out)
	GeneralVariables.input_mode_changed.connect(change_input)

## Starts the crystal bobbing animation.
func start_bobbing() -> void:
	rotationTween = create_tween()
	bobbingTween = create_tween()
	bobbingTween.tween_property(crystal, "position:y", 0.0, BOBBINGTIME / 2.0).set_trans(Tween.TRANS_SINE)
	bobbingTween.tween_property(crystal, "position:y", BOBBINGHEIGHT, BOBBINGTIME / 2.0).set_trans(Tween.TRANS_SINE)
	bobbingTween.set_loops()
	bobbingTween.play()
	rotationTween.tween_property(crystal, "rotation:y", deg_to_rad(360), ROTATIONTIME)
	rotationTween.tween_property(crystal, "rotation:y", 0.0, 0.0)
	rotationTween.set_loops()
	rotationTween.play()

## Shows the popup and hides the info icon.
func do_popup() -> void:
	if popupTween: popupTween.kill()
	popupTween = create_tween()
	popupTween.tween_property(infoIcon, "scale", Vector3.ONE * 0.001, INFOSHRINKTIME * infoIcon.scale.x).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	popupTween.tween_property(popupBoard, "scale", Vector3.ONE, POPUPTIME * (1.0 - popupBoard.scale.x)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	popupTween.play()
	popUpSound.play_sound()
	poppedUp = true

## Hides the popup and shows the info icon.
func do_popout() -> void:
	if popupTween: popupTween.kill()
	popupTween = create_tween()
	popupTween.tween_property(popupBoard, "scale", Vector3.ONE * 0.001, POPUPTIME * popupBoard.scale.x).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	popupTween.tween_property(infoIcon, "scale", Vector3.ONE, INFOSHRINKTIME * (1.0 - infoIcon.scale.x)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	popupTween.play()
	poppedUp = false

## Hides the popup and info icon when zooming out.
func zooming_out(zoomingOut: bool) -> void:
	if popupTween: popupTween.kill()
	popupTween = create_tween()
	if zoomingOut: popupTween.tween_property(popupBoard if poppedUp else infoIcon, "scale", Vector3.ONE * 0.001, HIDESHOWZOOMTIME * popupBoard.scale.x).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	else: popupTween.tween_property(popupBoard if poppedUp else infoIcon, "scale", Vector3.ONE, HIDESHOWZOOMTIME * (1.0 - infoIcon.scale.x)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	popupTween.play()

## Changes the popup sprite to controller if isGamepad is true or keyboard if false.
func change_input(isGamepad: bool) -> void:
	if isGamepad: popupBoard.texture = infoSpriteController
	else: popupBoard.texture = infoSpriteKeyboard
