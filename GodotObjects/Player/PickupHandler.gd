@tool
extends Area3D
class_name PickupHandler

var pickups: Array[Node3D]
var pickupOnHand: bool = false
var currentPickup: StickerBase

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if not pickupOnHand:
			do_grab()
		else:
			drop()

func do_grab() -> void:
	pickups = get_overlapping_bodies()
	var closest: Node3D
	var shortestDistance: float = 9999999999
	if pickups.size() > 0:
		for pickup in pickups:
			var currentDistance: float = global_position.distance_to(pickup.global_position)
			if currentDistance < shortestDistance:
				closest = pickup
				shortestDistance = currentDistance
		currentPickup = closest
		currentPickup.reparent(self)
		currentPickup.grab(self)
		pickupOnHand = true

func check_available_area() -> void:
	var areas: Array[Area3D] = get_overlapping_areas()
	var closest: Area3D
	var shortestDistance: float = 9999999999
	if len(areas) > 0:
		for area in areas:
			var currentDistance: float = global_position.distance_to(area.global_position)
			if currentDistance < shortestDistance:
				closest = area
				shortestDistance = currentDistance
		currentPickup.place_sticker(closest.global_position, closest.get_meta("pointing"))
		return
	if currentPickup: currentPickup.drop()

func drop() -> void:
	if pickupOnHand and currentPickup != null:
			check_available_area()
			currentPickup = null
			pickupOnHand = false
