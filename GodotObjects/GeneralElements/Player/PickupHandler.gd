@tool
extends Area3D
## Pickup Handler object. The grabbing area.
class_name PickupHandler

## Offset that the area highlight get displaced when shown
const AREAHIGHLIGHTOFFSET: float = 0.01
## Length of bobbing in the y axis.
const STICKERHIGHLIGHTBOBDISTANCE: float = 0.1
## Amount of time the bobbing animation takes.
const STICKERHIGHLIGHTBOBTIME: float = 0.5
## Maximum surface distance
const MAXSURFACEDISTANCE: float = 2.25

## Pick up sound player reference
@onready var pickupSound: RandomPitchPlayer = $Pickup
## Remove sound player reference
@onready var removeSound: RandomPitchPlayer = $Remove
## Drop sound player reference
@onready var dropSound: RandomPitchPlayer = $Drop
## Stick sound player reference
@onready var stickSound: RandomPitchPlayer = $Stick
## Sticker highlight sprite reference
@onready var highlight: Sprite3D = %Highlight
## Area highlight sprite reference
@onready var areaHighlight: Sprite3D = %AreaHighlight
## HighligtPivot reference for position placement
@onready var highlightPivot: Node3D = %HighlightPivot
## PlaceholderArea reference for sticker placement detection
@onready var placeholderArea: Area3D = %PlaceholderArea

## List of stickers in grabbing range
var closeStickers: Array[StickerBase] = []
## List of areas in range for placement
var closeAreas: Array[Area3D] = []
## Starting highlight height
var highlightHeight: float
## Current closest area available for placement
var currentArea: Area3D
## Flag that turns true when 
var pickupOnHand: bool = false
## Reference to the current pick up on the player
var currentPickup: StickerBase
## Flag that allows or stops the player from being able to grab a sticker
var canGrab: bool = true
## Flag that allows or stops the player from being able to drop a sticker
var canDrop: bool = true
## Flag turns true when zooming out
var zoomedOut: bool = false
## Tween for the highlight bobbing animation
var stickerHighlightTween: Tween
## The valid surfaces for stickers
var stickerableSurfaces: Dictionary[Vector3, Vector3] = {}
## Surfaces that already hold stickers
var surfacesWithStickers: PackedVector3Array = []

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.is_editor_hint(): return
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	highlightHeight = highlight.position.y
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	bob_sticker_hightlight()

## Called during the physics processing step of the main loop.
func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint(): return
	sort_close_stickers()
	sort_close_areas()

## Handles player input.
func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint(): return
	if event.is_action_pressed("interact") and not zoomedOut and canGrab:
		if not pickupOnHand:
			do_grab()
		else:
			drop()

## Grabs the closest sticker available
func do_grab() -> void:
	if len(closeStickers) == 0: return
	currentPickup = closeStickers[0]
	if currentPickup.placed:
		removeSound.play_sound()
		if surfacesWithStickers.has(currentPickup.placedPosition): surfacesWithStickers.remove_at(surfacesWithStickers.find(currentPickup.placedPosition))
	else: pickupSound.play_sound()
	currentPickup.reparent(self)
	currentPickup.grab(self)
	pickupOnHand = true
	currentPickup.activate_on_player_effect()

## Checks for available areas to place a sticker
func check_available_area(onReset: bool = false) -> bool:
	if currentArea and not onReset:
		currentPickup.place_sticker(currentArea, currentArea.get_meta("pointing"), currentArea == placeholderArea)
		if currentArea == placeholderArea: surfacesWithStickers.append(placeholderArea.global_position)
		stickSound.play_sound()
		return true
	return false

## Tries to place sticker, if it can't it drops it on the ground
func drop(onReset: bool = false) -> void:
	if pickupOnHand and currentPickup:
		currentPickup.deactivate_on_player_effect()
		if not check_available_area(onReset):
			if not canDrop: return
			currentPickup.drop()
			dropSound.play_sound()
		currentPickup = null
		pickupOnHand = false

## When a sticker body is detected it adds it to the closeStickers list
func _on_body_entered(body: Node3D) -> void:
	if body is not StickerBase: return
	if body not in closeStickers: closeStickers.append(body)

## When a sticker body exits the grabbing area it's removed from the closeStickers list
func _on_body_exited(body: Node3D) -> void:
	if body is not StickerBase: return
	closeStickers.erase(body)

## Sorts the closeSticker list by distance and shows sticker highlight when possible
func sort_close_stickers() -> void:
	closeStickers.sort_custom(func(a: StickerBase, b: StickerBase): return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position))
	if len(closeStickers) == 0 or pickupOnHand: 
		if highlight: highlight.hide()
	elif highlight:
		highlightPivot.global_position = closeStickers[0].global_position
		highlight.show()

## When a placement area is detected it's added to the closeAreas list
func _on_area_entered(area: Area3D) -> void:
	closeAreas.append(area)

## When a placement area exits the placement area it's removed from the closeAreas list
func _on_area_exited(area: Area3D) -> void:
	closeAreas.erase(area)

## Fetches valid surfaces for stickers.
func _fetch_valid_surfaces() -> void:
	for gridmap: StickerGridmap in get_tree().get_nodes_in_group("Gridmap"):
		for key in gridmap.stickerableSurfaces:
			stickerableSurfaces[key] = gridmap.stickerableSurfaces[key]

## Sorts the closeAreas list by distance and shows area highlight when possible
func sort_close_areas() -> void:
	## TEST
	if len(stickerableSurfaces.keys()) > 0:
		var surfaceArray: Array[Vector3] = stickerableSurfaces.keys()
		surfaceArray.sort_custom(func(sa: Vector3, sb: Vector3): return global_position.distance_to(sa) < global_position.distance_to(sb))
		surfaceArray = surfaceArray.filter(func(s: Vector3): return s not in surfacesWithStickers)
		if global_position.distance_to(surfaceArray[0]) > MAXSURFACEDISTANCE:
			placeholderArea.set_deferred("monitorable", false)
		else:
			placeholderArea.global_position = surfaceArray[0]
			placeholderArea.set_deferred("monitorable", true)
			placeholderArea.set_meta("pointing", stickerableSurfaces[surfaceArray[0]])
	
	closeAreas.sort_custom(func(a: Area3D, b: Area3D): return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position))
	if not pickupOnHand:
		if areaHighlight: areaHighlight.hide()
	elif areaHighlight:
		var currentIndex: int = closeAreas.find_custom(get_closest_valid)
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

## Returns true if the given area is valid for placing the current sticker
func get_closest_valid(area: Area3D) -> bool:
	return currentPickup.validAreaIndexes.any(func(index: int): return area.get_collision_layer_value(index)) and not area.get_children().any(func(child: Node3D): return child is StickerBase)

## Starts the sticker highlight bobbing animation
func bob_sticker_hightlight() -> void:
	stickerHighlightTween = create_tween()
	stickerHighlightTween.tween_property(highlight, "position:y", highlightHeight, STICKERHIGHLIGHTBOBTIME).set_trans(Tween.TRANS_SINE)
	stickerHighlightTween.tween_property(highlight, "position:y", highlightHeight + STICKERHIGHLIGHTBOBDISTANCE, STICKERHIGHLIGHTBOBTIME).set_trans(Tween.TRANS_SINE)
	stickerHighlightTween.set_loops()
	stickerHighlightTween.play()
