extends Node

## Handles interaction with darkness and lamps
class_name DarknessBlockerModule

## Parent reference.
@onready var parent: PhysicsBody3D
## Parent GrabArea reference.
@onready var grabArea: PickupHandler

## Accumultation of light areas.
var lightAreas: Array[Node]
## Accumultation of sticker light areas.
var stickerLightAreas: Array[Node]
## Accumultation of light areas.
var lightAreaDetectors: Array[Node]
## Accumultation of darkness areas.
var darknessAreas: Array[Node]
## Is holding a light.
var holdingLight: bool = false

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	parent = get_parent()
	parent.set_collision_mask_value(4, true)
	if parent.has_node("GrabArea"):
		grabArea = parent.get_node("GrabArea")

## Handles light area modifications.
func light_area(lightArea: Node, entered: bool) -> void:
	if entered:
		if lightArea in lightAreas: return
		lightAreas.append(lightArea)
	else:
		lightAreas.erase(lightArea)

## Handles sticker light area modifications, mainly here to make sure the player doesn't drop stickers too close to the darkness.
func sticker_light_area(lightArea: Node, entered: bool) -> void:
	if entered:
		if lightArea in stickerLightAreas: return
		stickerLightAreas.append(lightArea)
		grabArea.inLight = true
	else:
		stickerLightAreas.erase(lightArea)
		if len(stickerLightAreas) == 0: 
			grabArea.inLight = false

## Handles darkness area modifications.
func darkness_area(darknessArea: Node, entered: bool) -> void:
	if entered:
		if darknessArea in darknessAreas: return
		darknessAreas.append(darknessArea)
		if not grabArea: return
		grabArea.inDarkness = true
	else:
		darknessAreas.erase(darknessArea)
		if not grabArea: return
		if len(darknessAreas) == 0: grabArea.inDarkness = false

## Handles holding a light.
func holding_light(mode: bool) -> void:
	parent.set_collision_mask_value(4, not mode)
	holdingLight = mode
