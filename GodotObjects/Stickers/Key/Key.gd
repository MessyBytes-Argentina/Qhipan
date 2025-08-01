extends StickerBase

@onready var animationPlayer: AnimationPlayer = %AnimationPlayer

func place_sticker(area: Area3D, direction: Vector3) -> void:
	super(area, direction)
	#animationPlayer.play("SpinUp")
	check_door()

func grab(node: Node3D) -> void:
	super(node)
	#animationPlayer.play("RESET")

func check_door() -> void:
	var bodyList: Array[Node3D] = areaChecker.get_overlapping_bodies()
	for object in bodyList:
		if object is DoorBody:
			open_door(object)

func open_door(door: DoorBody) -> void:
	door.open_door()
