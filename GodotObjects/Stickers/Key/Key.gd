extends StickerBase
class_name Key

@onready var animationPlayer: AnimationPlayer = %AnimationPlayer
@onready var collisionShape3d: CollisionShape3D = %CollisionShape3D

var door: DoorBody

func _ready() -> void:
	super()
	animationPlayer.play("RESET")

func place_sticker(area: Area3D, direction: Vector3) -> void:
	super(area, direction)
	#animationPlayer.play("SpinUp")
	await get_tree().create_timer(0.1).timeout
	check_door()

func check_door():
	var bodyList: Array = areaChecker.get_overlapping_bodies()
	for object in bodyList:
		if object is DoorBody:
			door = object
			areaChecker.set_deferred("monitoring", false)
			areaChecker.set_deferred("monitorable", false)
			collisionShape3d.set_deferred("disabled", true)
			animationPlayer.play("PowerUp")

func open_door() -> void:
	door.open_door()
	#hide()
