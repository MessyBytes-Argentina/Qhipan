@tool
extends StickerBase
## Key sticker class.
class_name KeySticker

## Animation player reference.
@onready var animationPlayer: AnimationPlayer = %AnimationPlayer
## Body CollisionShape3D reference
@onready var collisionShape3d: CollisionShape3D = %CollisionShape3D

## has the key been used.
var used: bool = false

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	if Engine.is_editor_hint(): return
	animationPlayer.play("RESET")

## Places the sticker and checks for door
func place_sticker(pos: Vector3, direction: Vector3, overrideSize: Vector3 = Vector3.ONE) -> void:
	super(pos, direction, overrideSize)
	await get_tree().create_timer(0.1).timeout
	check_pedestal()

## Checks if it has a pedestal as an ancestor, if true disables the key and starts the animation
func check_pedestal():
	if get_parent() == sceneParent: return
	var superParent: Node3D = get_parent().get_parent()
	if superParent is SmallPedestal:
		superParent.activate_pedestal()
		areaChecker.set_deferred("monitoring", false)
		areaChecker.set_deferred("monitorable", false)
		collisionShape3d.set_deferred("disabled", true)
		animationPlayer.play("PowerUp")
		used = true
