extends Area3D

const BOBBINGHEIGHT: float = 0.1
const BOBBINGTIME: float = 3.0
const ROTATIONTIME: float = 5.0
const POPUPTIME: float = 0.4
const INFOSHRINKTIME: float = 0.1

@export var infoSprite: Texture2D

@onready var crystal: MeshInstance3D = $Crystal
@onready var infoIcon: Sprite3D = %InfoIcon
@onready var popupBoard: Sprite3D = %PopupBoard
@onready var popUpSound: RandomPitchPlayer = %PopUpSound

var rotationTween: Tween
var bobbingTween: Tween
var popupTween: Tween

func _ready() -> void:
	start_bobbing()
	body_entered.connect(do_popup.unbind(1))
	body_exited.connect(do_popout.unbind(1))
	popupBoard.texture = infoSprite
	await get_tree().create_timer(0.1).timeout
	popupBoard.scale = Vector3.ONE * 0.001

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

func do_popout() -> void:
	if popupTween: popupTween.kill()
	popupTween = create_tween()
	popupTween.tween_property(popupBoard, "scale", Vector3.ONE * 0.001, POPUPTIME * popupBoard.scale.x).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	popupTween.tween_property(infoIcon, "scale", Vector3.ONE, INFOSHRINKTIME * (1.0 - infoIcon.scale.x)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	popupTween.play()
