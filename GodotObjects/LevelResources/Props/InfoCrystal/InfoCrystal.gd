extends Area3D

const BOBBINGHEIGHT: float = 0.1
const BOBBINGTIME: float = 3.0
const ROTATIONTIME: float = 5.0
const POPUPTIME: float = 0.4
const INFOSHRINKTIME: float = 0.1
const HIDESHOWZOOMTIME: float = 0.2

@export var infoSpriteKeyboard: Texture2D
@export var infoSpriteController: Texture2D

@onready var crystal: MeshInstance3D = $Crystal
@onready var infoIcon: Sprite3D = %InfoIcon
@onready var popupBoard: Sprite3D = %PopupBoard
@onready var popUpSound: RandomPitchPlayer = %PopUpSound

var rotationTween: Tween
var bobbingTween: Tween
var popupTween: Tween
var player: Player
var poppedUp: bool = false

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

func do_popup() -> void:
	if popupTween: popupTween.kill()
	popupTween = create_tween()
	popupTween.tween_property(infoIcon, "scale", Vector3.ONE * 0.001, INFOSHRINKTIME * infoIcon.scale.x).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	popupTween.tween_property(popupBoard, "scale", Vector3.ONE, POPUPTIME * (1.0 - popupBoard.scale.x)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	popupTween.play()
	popUpSound.play_sound()
	poppedUp = true

func do_popout() -> void:
	if popupTween: popupTween.kill()
	popupTween = create_tween()
	popupTween.tween_property(popupBoard, "scale", Vector3.ONE * 0.001, POPUPTIME * popupBoard.scale.x).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	popupTween.tween_property(infoIcon, "scale", Vector3.ONE, INFOSHRINKTIME * (1.0 - infoIcon.scale.x)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	popupTween.play()
	poppedUp = false

func zooming_out(zoomingOut: bool) -> void:
	if popupTween: popupTween.kill()
	popupTween = create_tween()
	if zoomingOut: popupTween.tween_property(popupBoard if poppedUp else infoIcon, "scale", Vector3.ONE * 0.001, HIDESHOWZOOMTIME * popupBoard.scale.x).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	else: popupTween.tween_property(popupBoard if poppedUp else infoIcon, "scale", Vector3.ONE, HIDESHOWZOOMTIME * (1.0 - infoIcon.scale.x)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	popupTween.play()

func change_input(isGamepad: bool) -> void:
	if isGamepad: popupBoard.texture = infoSpriteController
	else: popupBoard.texture = infoSpriteKeyboard
