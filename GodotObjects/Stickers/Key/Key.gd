extends StickerBase
class_name Key

@onready var animationPlayer: AnimationPlayer = %AnimationPlayer
@onready var areaShape: CollisionShape3D = %CollisionShape3D

func place_sticker(area: Area3D, direction: Vector3) -> void:
	super(area, direction)
	#animationPlayer.play("SpinUp")
	await get_tree().create_timer(0.1).timeout
	check_door()

func grab(node: Node3D) -> void:
	super(node)
	#animationPlayer.play("RESET")

func check_door():
	var bodyList: Array = areaChecker.get_overlapping_bodies()
	for object in bodyList:
		if object is DoorBody:
			open_door(object)

func open_door(door: DoorBody) -> void:
	door.open_door()
	hide()
	areaShape.disabled = true
