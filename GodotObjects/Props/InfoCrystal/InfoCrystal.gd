extends Node3D

const BOBBINGHEIGHT: float = 0.1
const BOBBINGTIME: float = 3.0
const ROTATIONTIME: float = 5.0
const POPUPTIME: float = 0.4
const POPUPPIXELSIZE: float = 0.01
const INFOPIXELSIZE: float = 0.0005
const INFOSHRINKTIME: float = 0.1

@export var infoSprite: Texture2D

@onready var crystal: MeshInstance3D = $Crystal
@onready var infoIcon: Sprite3D = %InfoIcon
@onready var infoBoard: Sprite3D = %InfoBoard
@onready var textureRect: TextureRect = %TextureRect

var rotationTween: Tween
var bobbingTween: Tween
var popupTween: Tween

func _ready() -> void:
	start_bobbing()
	textureRect.texture = infoSprite

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
	popupTween = create_tween()
	popupTween.tween_property(infoIcon, "pixel_size", 0.0, INFOSHRINKTIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	popupTween.tween_property(infoBoard, "pixel_size", POPUPPIXELSIZE, POPUPTIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	popupTween.play()

func do_popout() -> void:
	popupTween = create_tween()
	popupTween.tween_property(infoBoard, "pixel_size", 0.0, inverse_lerp(0.0, POPUPPIXELSIZE, infoBoard.pixel_size) * POPUPTIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	popupTween.tween_property(infoIcon, "pixel_size", INFOPIXELSIZE, INFOSHRINKTIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	popupTween.play()
