extends StickerBase

@onready var heldAreaChecker: Area3D = %HeldAreaChecker

var objectCollection: Array

func _ready() -> void:
	super()
	heldAreaChecker.body_entered.connect(switch_object)
	heldAreaChecker.body_exited.connect(switch_object)

func switch_object(obj) -> void:
	obj.switch_state()

func place_sticker(area: Area3D, direction: Vector3, isPlaceholderArea: bool = false) -> void:
	super(area,direction,isPlaceholderArea)
	heldAreaChecker.monitoring = true

func grab(node: Node3D) -> void:
	super(node)
	heldAreaChecker.monitoring = true

func drop() -> void:
	super()
	heldAreaChecker.monitoring = false
