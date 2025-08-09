@tool
extends Area3D
class_name PickupHandler

const AREAHIGHLIGHTOFFSET: float = 0.01

@onready var pickupSound: RandomPitchPlayer = $Pickup
@onready var removeSound: RandomPitchPlayer = $Remove
@onready var dropSound: RandomPitchPlayer = $Drop
@onready var stickSound: RandomPitchPlayer = $Stick
@onready var highlight: Sprite3D = $Highlight
@onready var areaHighlight: Sprite3D = $AreaHighlight

var closeStickers: Array[StickerBase] = []
var closeAreas: Array[Area3D] = []
var highlightHeight: float
var currentArea: Area3D
var pickups: Array[Node3D]
var pickupOnHand: bool = false
var currentPickup: StickerBase
var canGrab: bool = true
var canDrop: bool = true
var zoomedOut: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	highlightHeight = highlight.position.y
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _physics_process(_delta: float) -> void:
	sort_close_stickers()
	sort_close_areas()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not zoomedOut and canGrab:
		if not pickupOnHand:
			do_grab()
		else:
			drop()

func do_grab() -> void:
	if len(closeStickers) == 0: return
	currentPickup = closeStickers[0]
	if currentPickup.placed: removeSound.play_sound()
	else: pickupSound.play_sound()
	currentPickup.reparent(self)
	currentPickup.grab(self)
	pickupOnHand = true

func check_available_area(onReset: bool = false) -> bool:
	if currentArea and not onReset:
		currentPickup.place_sticker(currentArea, currentArea.get_meta("pointing"))
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

func _on_body_entered(body: Node3D) -> void:
	if body is not StickerBase: return
	if body not in closeStickers: closeStickers.append(body)

func _on_body_exited(body: Node3D) -> void:
	if body is not StickerBase: return
	closeStickers.erase(body)

func sort_close_stickers() -> void:
	closeStickers.sort_custom(func(a: StickerBase, b: StickerBase): return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position))
	if len(closeStickers) == 0 or pickupOnHand: 
		if highlight: highlight.hide()
	elif highlight:
		highlight.global_position = closeStickers[0].global_position + Vector3.UP * highlightHeight
		highlight.show()

func _on_area_entered(area: Area3D) -> void:
	closeAreas.append(area)

func _on_area_exited(area: Area3D) -> void:
	closeAreas.erase(area)

func sort_close_areas() -> void:
	closeAreas.sort_custom(func(a: Area3D, b: Area3D): return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position))
	if not pickupOnHand:
		if areaHighlight: areaHighlight.hide()
	elif areaHighlight:
		var currentIndex: int = closeAreas.find_custom(func(a: Area3D): return currentPickup.validAreaIndexes.any(func(index: int): return a.get_collision_layer_value(index)))
		currentArea = closeAreas[currentIndex] if currentIndex > -1 else null
		if not currentArea:
			areaHighlight.hide()
			return
		areaHighlight.global_position = currentArea.global_position + currentArea.get_meta("pointing") * AREAHIGHLIGHTOFFSET
		if not Vector3.UP.cross(currentArea.get_meta("pointing")).is_zero_approx():
			areaHighlight.look_at(areaHighlight.global_position + currentArea.get_meta("pointing"))
		else:
			areaHighlight.look_at(areaHighlight.global_position + currentArea.get_meta("pointing"), Vector3.FORWARD)
		areaHighlight.show()
