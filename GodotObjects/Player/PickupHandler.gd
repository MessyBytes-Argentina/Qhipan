@tool
extends Area3D
class_name PickupHandler

var pickups: Array[Node3D]
var pickupOnHand: bool = false
var currentPickup: StickerBase
var canDrop: bool = true

@onready var pickupSound: RandomPitchPlayer = $Pickup
@onready var removeSound: RandomPitchPlayer = $Remove
@onready var dropSound: RandomPitchPlayer = $Drop
@onready var stickSound: RandomPitchPlayer = $Stick

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
		if currentPickup.placed: removeSound.play_sound()
		else: pickupSound.play_sound()
		currentPickup.reparent(self)
		currentPickup.grab(self)
		pickupOnHand = true

func check_available_area(onReset: bool = false) -> bool:
	var areas: Array[Area3D] = get_overlapping_areas()
	var closest: Area3D
	var shortestDistance: float = 9999999999
	if len(areas) > 0 and not onReset:
		for area in areas:
			var currentDistance: float = global_position.distance_to(area.global_position)
			var hasSticker: bool = area.get_children().any(func(a: Node): return a is StickerBase)
			if currentDistance < shortestDistance and not hasSticker:
				closest = area
				shortestDistance = currentDistance
		if closest and closest.get_collision_layer_value(11):
			currentPickup.place_sticker(closest, closest.get_meta("pointing"))
			stickSound.play_sound()
			return true
		elif closest and closest.get_collision_layer_value(12) and currentPickup is Key:
			currentPickup.place_sticker(closest, closest.get_meta("pointing"))
			stickSound.play_sound()
			return true
	return false

func drop(onReset: bool = false) -> void:
	if pickupOnHand and currentPickup:
		if not check_available_area(onReset):
			if not canDrop: return
			currentPickup.drop()
			dropSound.play_sound()
		currentPickup = null
		pickupOnHand = false
