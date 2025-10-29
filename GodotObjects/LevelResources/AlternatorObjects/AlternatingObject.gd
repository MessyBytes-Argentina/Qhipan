@tool
extends CharacterBody3D
class_name AlternatingObject

const MATERIALS: Dictionary = {
	"ON": preload("uid://cp14w7jqyffv3"),
	"OFF": preload("uid://mijic4patrrf")
}

@export var isOff: bool = false:
	set(value):
		isOff = value
		if not Engine.is_editor_hint(): return
		if isOff:
			objMesh.set_surface_override_material(0, MATERIALS.OFF)
		else:
			objMesh.set_surface_override_material(0, MATERIALS.ON)

@onready var objMesh: MeshInstance3D = %ObjectMesh
@onready var objCollider: CollisionShape3D = %ObjectCollider

var groupParent: AlternatingGroup

func _ready() -> void:
	if Engine.is_editor_hint():
		if isOff:
			objMesh.set_surface_override_material(0, MATERIALS.OFF)
		else:
			objMesh.set_surface_override_material(0, MATERIALS.ON)
		return
	if isOff:
		turn_off()
	else:
		turn_on()
	var parent = get_parent()
	if parent is AlternatingGroup: 
		groupParent = parent
	else:
		prints(name," isn't in a group")

func switch_state() -> void:
	if isOff:
		turn_on()
	else:
		turn_off()
	isOff = !isOff

func turn_on() -> void:
	objMesh.set_surface_override_material(0, MATERIALS.ON)
	objCollider.set_deferred("disabled", false)

func turn_off() -> void:
	objMesh.set_surface_override_material(0, MATERIALS.OFF)
	objCollider.set_deferred("disabled", true)
