extends CharacterBody3D
class_name AlternatingObject

@export var currentlyOn: bool = true

@onready var objMesh: MeshInstance3D = %ObjectMesh
@onready var objCollider: CollisionShape3D = %ObjectCollider

var groupParent: AlternatingGroup

func _ready() -> void:
	if currentlyOn:
		turn_on()
	else:
		turn_off()
	var parent = get_parent()
	if parent is AlternatingGroup: 
		groupParent = parent
	else:
		prints(name," isn't in a group")

func switch_group() -> void:
	if groupParent:
		groupParent.switch_children(self)

func switch_state() -> void:
	if currentlyOn:
		turn_off()
	else:
		turn_on()
	currentlyOn = !currentlyOn

func turn_on() -> void:
	objMesh.show()
	objCollider.set_deferred("disabled", false)

func turn_off() -> void:
	objMesh.hide()
	objCollider.set_deferred("disabled", true)
