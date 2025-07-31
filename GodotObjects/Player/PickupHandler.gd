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
	var placements: Array = get_overlapping_areas()
	if placements.size() > 0:
		currentPickup.place_sticker(placements[0].get_target_position())
