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
## Maximum surface distance.
const MAXSURFACEDISTANCE: float = 2.25
## Collision layers to block raycast.
const RAYCOLLISIONLAYERS: Array[int] = [1, 3, 4, 9, 13]
## Sticker area radius.
const STICKERRADIUS: float = 0.132
## Sticker list
enum StickerList {ALTERNATOR = 1, FAN = 2, LAMP = 4, KEY = 8, INVENTORY = 16}

## Sprite pivot reference.
@export var spriteSocket: Node3D

## Pick up sound player reference
@onready var pickupSound: RandomSoundPlayer = $Pickup
## Remove sound player reference
@onready var removeSound: RandomSoundPlayer = $Remove
## Drop sound player reference
@onready var dropSound: RandomSoundPlayer = $Drop
## Stick sound player reference
@onready var stickSound: RandomSoundPlayer = $Stick
## Sticker highlight sprite reference
@onready var highlight: Sprite3D = %Highlight
## Area highlight sprite reference
@onready var areaHighlight: Sprite3D = %AreaHighlight
## HighligtPivot reference for position placement
@onready var highlightPivot: Node3D = %HighlightPivot
## PlaceholderArea reference for sticker placement detection
@onready var placeholderArea: Area3D = %PlaceholderArea
## Timer reference for pick up cooldown
@onready var pickupCd: Timer = $PickupCooldown

## Reference to the player.
var player: Player

## List of stickers in grabbing range
var closeStickers: Array[StickerBase] = []
## List of valid stickers
var currentlyAvailableStickers: Array[StickerBase] = []
## Starting highlight height
var highlightHeight: float
## Flag that turns true when 
var pickupOnHand: bool = false
## Reference to the current pick up on the player
var currentPickup: StickerBase
## Flag that allows or stops the player from being able to grab a sticker when in a no sticker area
var inNoStickerArea: bool = false
## Flag that allows or stops the player from being able to grab a sticker
var canGrab: bool = true
## Flag that allows or stops the player from being able to drop a sticker
var canDrop: bool = true
## Flag that allows or stops the player from being able to drop a sticker while in darkness
var inDarkness: bool = false
## Flag that allows or stops the player from being able to drop a sticker while in darkness and light
var inLight: bool = false
## Flag turns true when zooming out
var zoomedOut: bool = false
## Blocked stickers array
var blockedStickersArray: Array[int] = []
## Actually blocked stickers
var blockedStickers: int
## Tween for the highlight bobbing animation
var stickerHighlightTween: Tween
## Collection of areas that stop the player from dropping or grabbing stickers
var antiDropAreaCollection: Array[AntiDropArea] = []
## Layers turned into usable mask
var layerMask: int
## Sticker mask for when all stickers are available
var stickerMask: int
## Last global position to detect movement
var lastPos: Vector3

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.is_editor_hint(): return
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	highlightHeight = highlight.position.y
	area_exited.connect(_on_area_exited)
	bob_sticker_hightlight()
	layerMask = RAYCOLLISIONLAYERS.reduce(func(accum: int, a: int = 0): return accum + pow(2, a - 1), 0)
	stickerMask = StickerList.keys().reduce(func(accum: int, a: StringName): return accum + StickerList[a], 0)
	blockedStickers = stickerMask

## Called during the physics processing step of the main loop.
func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint(): return
	if lastPos != global_position:
		sort_close_stickers()
	lastPos = global_position
	get_closest_surface()

## Handles player input.
func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint(): return
	if player.onSettings: return
	if not zoomedOut and canGrab and not inNoStickerArea:
		if event.is_action_pressed("interact") and pickupCd.is_stopped():
			if len(antiDropAreaCollection) > 0: return
			#if not pickupOnHand:
				#do_grab()
			#elif get_sticker_class(currentPickup) & blockedStickers != 0:
				#drop()
			if pickupOnHand:
				if get_sticker_class(currentPickup) & blockedStickers != 0:
					drop()
				if len(currentlyAvailableStickers) > 0:
					do_grab()
			elif len(currentlyAvailableStickers) > 0:
				do_grab()
			sort_close_stickers()
			pickupCd.start()
		if event.is_action_pressed("cycle_stickers"):
			cycle_stickers()

## Checks for sticker class
func get_sticker_class(sticker: StickerBase) -> StickerList:
	if sticker is AlternatorSticker: return StickerList.ALTERNATOR
	if sticker is FanSticker: return StickerList.FAN
	if sticker is LampSticker: return StickerList.LAMP
	if sticker is KeySticker: return StickerList.KEY
	else: return StickerList.INVENTORY

## Grabs the closest sticker available
func do_grab() -> void:
	if len(currentlyAvailableStickers) == 0: return
	currentPickup = currentlyAvailableStickers[0]
	if currentPickup.placed:
		removeSound.play_sound()
		var surface: StickerableSurfaceData = GeneralVariables.stickerableSurfacesManager.get_surface_with_sticker(currentPickup)
		if surface: 
			surface.node.sticker_activity()
			surface.used = null
	elif currentPickup is not InventorySticker: pickupSound.play_sound()
	currentPickup.grab(spriteSocket if spriteSocket else self)
	currentPickup.reparent(spriteSocket if spriteSocket else self)
	pickupOnHand = true
	currentPickup.activate_on_player_effect()

## Checks for available areas to place a sticker
func check_available_area() -> bool:
	if areaHighlight.visible:
		player.animation_check(Player.States.Slap)
		return true
	return false

## Adds or removes stickers block to queue
func sticker_block(stickerTypes: int, doAdd: bool) -> void:
	if doAdd: blockedStickersArray.append(stickerTypes)
	else: blockedStickersArray.erase(stickerTypes)
	if len(blockedStickersArray) == 0: blockedStickers = stickerMask
	else: blockedStickers = blockedStickersArray.reduce(func(accum: int, a: int): return accum & ~a, stickerMask)

## Places the sticker on hand
func place_sticker() -> void:
	var surface: StickerableSurfaceData = GeneralVariables.stickerableSurfacesManager.get_surface_with_position(placeholderArea.global_position)
	if surface: surface.used = currentPickup
	currentPickup.place_sticker(surface.globalPosition, surface.direction, surface.specialScale, surface.specialFlags, surface.extraParameters)
	surface.node.sticker_activity()
	surface.used = currentPickup
	stickSound.play_sound()
	currentPickup.deactivate_on_player_effect()
	currentPickup = null
	pickupOnHand = false

## Tries to place sticker, if it can't it drops it on the ground
func drop(onReset: bool = false, forceDrop: bool = false) -> void:
	if pickupOnHand and currentPickup:
		if onReset:
			currentPickup.reset_sticker()
		elif forceDrop:
			currentPickup.drop()
			dropSound.play_sound()
		elif not check_available_area():
			if not canDrop or (inDarkness and not inLight and currentPickup is LampSticker): return
			currentPickup.drop()
			dropSound.play_sound()
		else: return
		currentPickup.deactivate_on_player_effect()
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

## Sorts the closeSticker list by distance and checks for highlight
func sort_close_stickers() -> void:
	closeStickers.sort_custom(func(a: StickerBase, b: StickerBase): return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position))
	currentlyAvailableStickers = closeStickers.duplicate()
	if currentlyAvailableStickers.has(currentPickup):
		currentlyAvailableStickers.erase(currentPickup)
	var spaceState: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	currentlyAvailableStickers = currentlyAvailableStickers.filter(func(a: StickerBase): 
		if get_sticker_class(a) & blockedStickers == 0: return false
		if a.inDarkness: return false
		if global_position.distance_to(a.global_position) <= STICKERRADIUS: return true
		var raycast = PhysicsRayQueryParameters3D.create(global_position, global_position.direction_to(a.global_position) * (global_position.distance_to(a.global_position) - STICKERRADIUS) + global_position)
		raycast.collision_mask = layerMask
		return not spaceState.intersect_ray(raycast)
	)
	check_highlight()

## Shows sticker highlight when possible
func check_highlight() -> void:
	if len(currentlyAvailableStickers) == 0 or not canGrab or inNoStickerArea: 
		if highlight: highlight.hide()
	elif highlight:
		highlightPivot.global_position = currentlyAvailableStickers[0].global_position
		highlight.show()

## Cycles between available stickers if possible
func cycle_stickers() -> void:
	if len(currentlyAvailableStickers) <= 1 or not canGrab or inNoStickerArea: return
	currentlyAvailableStickers.push_back(currentlyAvailableStickers.pop_front())
	check_highlight()

## When a placement area exits the placement area it's removed from the closeAreas list
func _on_area_exited(_area: Area3D) -> void:
	areaHighlight.hide()

## Sorts the closeAreas list by distance and shows area highlight when possible
func get_closest_surface() -> void:
	if not pickupOnHand:
		if areaHighlight: areaHighlight.hide()
		return
	var closestSurface: StickerableSurfaceData = GeneralVariables.stickerableSurfacesManager.get_closest_valid_surface(global_position, currentPickup, global_position, layerMask, STICKERRADIUS, get_world_3d().direct_space_state)
	if closestSurface == null: return
	if global_position.distance_to(closestSurface.globalPosition) > MAXSURFACEDISTANCE:
		placeholderArea.set_deferred("monitorable", false)
		areaHighlight.hide()
		return
	placeholderArea.global_position = closestSurface.globalPosition
	placeholderArea.set_deferred("monitorable", true)
	areaHighlight.global_position = closestSurface.globalPosition + closestSurface.direction * AREAHIGHLIGHTOFFSET
	if not Vector3.UP.cross(closestSurface.direction).is_zero_approx():
		areaHighlight.look_at(areaHighlight.global_position + closestSurface.direction)
	else:
		areaHighlight.look_at(areaHighlight.global_position + closestSurface.direction, Vector3.FORWARD)
	if overlaps_area(placeholderArea): areaHighlight.show()

## Starts the sticker highlight bobbing animation
func bob_sticker_hightlight() -> void:
	stickerHighlightTween = create_tween()
	stickerHighlightTween.tween_property(highlight, "position:y", highlightHeight, STICKERHIGHLIGHTBOBTIME).set_trans(Tween.TRANS_SINE)
	stickerHighlightTween.tween_property(highlight, "position:y", highlightHeight + STICKERHIGHLIGHTBOBDISTANCE, STICKERHIGHLIGHTBOBTIME).set_trans(Tween.TRANS_SINE)
	stickerHighlightTween.set_loops()
	stickerHighlightTween.play()

## Adds the given area to antiDropAreaCollection
func add_anti_drop_area(area: AntiDropArea) -> void:
	if antiDropAreaCollection.has(area): return
	antiDropAreaCollection.append(area)

## Removes the given area to antiDropAreaCollection
func remove_anti_drop_area(area: AntiDropArea) -> void:
	if antiDropAreaCollection.has(area):
		antiDropAreaCollection.erase(area)

## Finish slap animation
func _slap_finished() -> void:
	player.animation_check(Player.States.Idle)
