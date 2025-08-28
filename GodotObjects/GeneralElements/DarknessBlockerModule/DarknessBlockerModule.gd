extends Node

## Handles interaction with darkness and lamps
class_name DarknessBlockerModule

## Parent reference.
@onready var parent: PhysicsBody3D
## Parent GrabArea reference.
@onready var grabArea: PickupHandler

## Accumultation of light areas.
var lightAreas: Array[Node]
## Accumultation of darkness areas.
var darknessAreas: Array[Node]

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_parent().set_collision_mask_value(4, true)
	parent = get_parent()
	if parent.has_node("GrabArea"):
		grabArea = parent.get_node("GrabArea")

func light_area_entered(lightArea: Node) -> void:
	if lightArea in lightAreas: return
	lightAreas.append(lightArea)
	parent.set_collision_mask_value(4, false)

func light_area_exited(lightArea: Node) -> void:
	lightAreas.erase(lightArea)
	if len(lightAreas) == 0: parent.set_collision_mask_value(4, true)

func darkness_area_entered(darknessArea: Node) -> void:
	if darknessArea in darknessAreas: return
	darknessAreas.append(darknessArea)
	if not grabArea: return
	grabArea.inDarkness = true

func darkness_area_exited(darknessArea: Node) -> void:
	darknessAreas.erase(darknessArea)
	if not grabArea: return
	if len(darknessAreas) == 0: grabArea.inDarkness = false
