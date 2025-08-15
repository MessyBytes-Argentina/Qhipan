extends StickerBase
class_name Key

## Animation player reference.
@onready var animationPlayer: AnimationPlayer = %AnimationPlayer
## Body CollisionShape3D reference
@onready var collisionShape3d: CollisionShape3D = %CollisionShape3D

## Door node reference for opening
var door: DoorBody

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	animationPlayer.play("RESET")

## Places the sticker and checks for door
func place_sticker(area: Area3D, direction: Vector3) -> void:
	super(area, direction)
	#animationPlayer.play("SpinUp")
	await get_tree().create_timer(0.1).timeout
	check_door()

## Checks if it has a door as an ancestor
## if true disables the key and starts the animation
func check_door():
	var superParent: Node3D = get_parent().get_parent()
	if superParent is DoorBody:
		door = superParent
		areaChecker.set_deferred("monitoring", false)
		areaChecker.set_deferred("monitorable", false)
		collisionShape3d.set_deferred("disabled", true)
		animationPlayer.play("PowerUp")

## Hodor isn't here
func open_door() -> void:
	if door: door.open_door()
	#hide()
