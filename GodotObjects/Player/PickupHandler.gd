extends Area3D

var pickups: Array[Node3D]
var pickupOnHand: bool = false
var currentPickup: StickerBase

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if not pickupOnHand:
			pickups = get_overlapping_bodies()
			if pickups.size() > 0:
				currentPickup = pickups[0]
				currentPickup.reparent(self)
				currentPickup.grab(self)
				pickupOnHand = true
		elif pickupOnHand and currentPickup != null:
			currentPickup.drop()
			check_available_area()
			currentPickup = null
			pickupOnHand = false

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
		currentPickup.place_sticker(closest.global_position)
