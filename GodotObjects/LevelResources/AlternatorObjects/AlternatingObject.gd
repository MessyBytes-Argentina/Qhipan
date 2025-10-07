extends CharacterBody3D
class_name AlternatingObject

@export var isPowered: bool = false

@onready var objMesh: MeshInstance3D = %ObjectMesh
@onready var objCollider: CollisionShape3D = %ObjectCollider

var groupParent: AlternatingGroup

func _ready() -> void:
	if isPowered:
		turn_off()
	else:
		turn_on()
	var parent = get_parent()
	if parent is AlternatingGroup: 
		groupParent = parent
	else:
		prints(name," isn't in a group")

func switch_state() -> void:
	if isPowered:
		turn_on()
	else:
		turn_off()
	isPowered = !isPowered

func turn_on() -> void:
	objMesh.show()
	objCollider.set_deferred("disabled", false)

func turn_off() -> void:
	objMesh.hide()
	objCollider.set_deferred("disabled", true)
