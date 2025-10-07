extends CharacterBody3D
class_name StickerBase

## Size of the sticker when the camera zooms out.
const ZOOMOUTSCALE: float = 0.5
## Size of the sticker when floating on the ground.
const BOBBINGSCALE: float = 0.5
## Length of bobbing in the y axis.
const BOBBINGHEIGHT: float = 0.05
## Amount of time the bobbing animation takes.
const BOBBINGTIME: float = 2.0
## Amount of time it takes the sticker to rotate.
const ROTATIONTIME: float = 3.0
## Angle of the sticker in the x axis when floating on the ground.
const TILTANGLE: float = deg_to_rad(-30)
## Height of the sticker when grabbed.
const GRABHEIGHT: float = 0.6
## Wait time to place when loading.
const PLACEDCHECKTIME: float = 0.25

## State of the sticker.
enum ScaleModes {GRABBED, DROPPED, PLACED, ZOOMEDOUT}

## If true checks for areas to place after loading.
@export var placed: bool = false
## Collision layer for sticker placement.
@export var validAreaIndexes: Array[int] = [11]

## Area3D to check for placement.
@onready var areaChecker: Area3D = %AreaChecker
## Front visual mesh reference.
@onready var mesh: MeshInstance3D = %Mesh
## Back visual mesh reference.
@onready var back: MeshInstance3D = %Back
## Reference to the parent of all meshes.
@onready var meshes: Node3D = %Meshes
## Shadow decal reference.
@onready var shadowDecal: Decal = %ShadowDecal
## Sticker billboard reference.
@onready var billboard: Sprite3D = %Billboard
## Sticker billboard on zoom out reference.
@onready var billboardZoomedOut: Sprite3D = %BillboardZoomedOut
## Reference to the involuntary movement module.
@onready var involuntaryPushModule: InvoluntaryPushModule = %InvoluntaryPushModule

## The collision mask for when the sticker is not on the player
var collisionMask: int
## Parent node reference for placement.
var sceneParent: Node
## Tween for rotation animation.
var rotationTween: Tween
## Tween for bobbing animation.
var bobbingTween: Tween
## Mesh size before modifications (not used?).
var startSize: Vector2
## Front mesh material reference to make unique.
var meshMaterial: StandardMaterial3D
## back mesh material reference to make unique.
var backMaterial: StandardMaterial3D
## Flag to not show the sticker on zoom out.
var grabed: bool = false
## Current state of the sticker.
var lastVisualMode: ScaleModes = ScaleModes.DROPPED
## Reference to the original parent of this sticker
var originalParent: Node
## Placed position reference for overlaps.
var placedPosition: Vector3
## Tracks darkness areas.
var darknessAreas: Array[Area3D] = []
## Tracks light areas.
var lightAreas: Array[Area3D] = []
## Prevents player from grabbing this sticker if it's in full darkness.
var inDarkness: bool = false
## Tracks the last location it was in last time it was grabbed.
var lastLocation: Vector3
## Tracks the state it was in last time it was grabbed.
var lastMode: bool = false

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	collisionMask = collision_mask
	sceneParent = get_parent()
	meshMaterial = mesh.get_surface_override_material(0).duplicate(true)
	mesh.set_surface_override_material(0, meshMaterial)
	mesh.mesh = mesh.mesh.duplicate()
	backMaterial = back.get_surface_override_material(0).duplicate()
	back.set_surface_override_material(0, backMaterial)
	startSize = mesh.mesh.size
	shadowDecal.size = Vector3(BOBBINGSCALE, shadowDecal.size.y, BOBBINGSCALE)
	prerender()
	get_tree().get_first_node_in_group("Player").zooming_out.connect(zooming_out)
	originalParent = get_parent()
	areaChecker.area_entered.connect(_on_area_entered)
	areaChecker.area_exited.connect(_on_area_exited)
	await get_tree().create_timer(PLACEDCHECKTIME).timeout
	check_placement()
	lastLocation = global_position
	lastMode = placed

## Checks for nearby areas to place itself
func check_placement() -> void:
	if not placed: 
		set_size(ScaleModes.DROPPED)
		set_deferred("collision_mask", collisionMask)
	else:
		var grabArea: PickupHandler = get_tree().get_first_node_in_group("Player").grabArea
		while len(grabArea.stickerableSurfaces) == 0:
			await get_tree().process_frame
		var surfaceArray: Array[Vector3] = grabArea.stickerableSurfaces.keys()
		surfaceArray.sort_custom(func(sa: Vector3, sb: Vector3): return global_position.distance_to(sa) < global_position.distance_to(sb))
		if len(surfaceArray) == 0:
			set_size(ScaleModes.DROPPED)
			return
		var closest: Vector3 = surfaceArray[0]
		var temporaryArea: Area3D = Area3D.new()
		add_child(temporaryArea)
		temporaryArea.global_position = closest
		#prints("sticker base")
		place_sticker(temporaryArea, grabArea.stickerableSurfaces[closest], true)
		temporaryArea.queue_free()
		if closest not in grabArea.surfacesWithStickers: grabArea.surfacesWithStickers.append(closest)
		shadowDecal.hide()

## Executed on every physics frame.
func _physics_process(delta: float) -> void:
	if placed or grabed: return
	var currentPush: Vector3 = involuntaryPushModule.get_current_push()
	velocity = currentPush * delta
	move_and_slide()

## Cabeza fix to load visuals
func prerender() -> void:
	mesh.show()
	back.show()
	billboard.show()
	billboardZoomedOut.show()
	await get_tree().create_timer(0.01).timeout
	mesh.hide()
	back.hide()
	billboard.hide()
	billboardZoomedOut.hide()
	await get_tree().create_timer(0.01).timeout
	mesh.show()
	back.show()
	billboard.show()
	billboardZoomedOut.show()
	await get_tree().create_timer(0.01).timeout
	billboard.hide()
	billboardZoomedOut.hide()

## Places the sticker on the given area facing the given direction
func place_sticker(area: Area3D, direction: Vector3, isPlaceholderArea: bool = false) -> void:
	set_size(ScaleModes.PLACED)
	placedPosition = area.global_position
	global_position = area.global_position + direction * 0.01
	placed = true
	grabed = false
	if not Vector3.UP.cross(direction).is_zero_approx():
		look_at(global_position - direction)
	else:
		look_at(global_position - direction, Vector3.FORWARD)
	if isPlaceholderArea:
		reparent(originalParent)
	else:
		reparent(area)

## Changes the current state and visuals to the given mode
func set_size(mode: ScaleModes) -> void:
	if mode != ScaleModes.ZOOMEDOUT: lastVisualMode = mode
	match mode:
		ScaleModes.GRABBED:
			billboard.show()
			mesh.hide()
			back.hide()
			billboardZoomedOut.hide()
			stop_rotation()
		ScaleModes.DROPPED:
			billboard.hide()
			mesh.show()
			back.show()
			billboardZoomedOut.hide()
			meshes.scale = Vector3.ONE * BOBBINGSCALE
			start_rotation()
		ScaleModes.PLACED:
			billboard.hide()
			mesh.show()
			back.show()
			billboardZoomedOut.hide()
			meshes.scale = Vector3.ONE
			stop_rotation()
		ScaleModes.ZOOMEDOUT:
			billboardZoomedOut.show()
			billboard.hide()
			mesh.hide()
			back.hide()
			meshes.scale = Vector3.ONE * ZOOMOUTSCALE

## Moves the sticker position to the given node position
func grab(node: Node3D) -> void:
	set_deferred("collision_mask", 0)
	lastLocation = global_position
	lastMode = placed
	global_position = node.global_position
	global_position.y = global_position.y + GRABHEIGHT
	rotation = Vector3.ZERO
	set_size(ScaleModes.GRABBED)
	grabed = true
	placed = false

## Called when player reset is called
func reset_sticker() -> void:
	reparent(sceneParent)
	grabed = false
	global_position = lastLocation
	placed = lastMode
	check_placement()

## Drops the sticker on the ground reparenting it to the scene
func drop() -> void:
	set_deferred("collision_mask", collisionMask)
	set_size(ScaleModes.DROPPED)
	global_position.y = global_position.y - GRABHEIGHT
	placed = false
	reparent(sceneParent)
	grabed = false

## Starts the floating animations 
func start_rotation() -> void:
	rotationTween = create_tween()
	bobbingTween = create_tween()
	meshes.position.y = BOBBINGHEIGHT
	meshes.rotation.x = TILTANGLE
	shadowDecal.show()
	bobbingTween.tween_property(meshes, "position:y", -BOBBINGHEIGHT, BOBBINGTIME / 2.0).set_trans(Tween.TRANS_SINE)
	bobbingTween.tween_property(meshes, "position:y", BOBBINGHEIGHT, BOBBINGTIME / 2.0).set_trans(Tween.TRANS_SINE)
	bobbingTween.set_loops()
	bobbingTween.play()
	rotationTween.tween_property(meshes, "rotation:y", deg_to_rad(360), ROTATIONTIME)
	rotationTween.tween_property(meshes, "rotation:y", 0.0, 0.0)
	rotationTween.set_loops()
	rotationTween.play()

## Stops floating animations
func stop_rotation() -> void:
	if rotationTween:
		rotationTween.kill()
	if bobbingTween:
		bobbingTween.kill()
	meshes.position.y = 0
	meshes.rotation.y = 0
	meshes.rotation.x = 0
	meshes.scale = Vector3.ONE
	shadowDecal.hide()

## Changes visual size on zoom out
func zooming_out(zoomedOut: bool) -> void:
	if not grabed: 
		if zoomedOut: 
			if lastVisualMode == ScaleModes.DROPPED: stop_rotation()
			set_size(ScaleModes.ZOOMEDOUT)
		else: 
			set_size(lastVisualMode)
			if lastVisualMode == ScaleModes.DROPPED: start_rotation()

## Activates the sticker effect when held by the player
func activate_on_player_effect() -> void:
	pass

## Deactivates the sticker effect when held by the player
func deactivate_on_player_effect() -> void:
	pass

## Tracks dark and light areas.
func _on_area_entered(area: Area3D) -> void:
	if area.get_collision_layer_value(4):
		if area in darknessAreas: return
		darknessAreas.append(area)
		if len(lightAreas) == 0: inDarkness = true
	if area.get_collision_layer_value(5):
		if area in lightAreas: return
		lightAreas.append(area)
		inDarkness = false

## Removes darkness and light areas from arrays.
func _on_area_exited(area: Area3D) -> void:
	darknessAreas.erase(area)
	lightAreas.erase(area)
	inDarkness = len(lightAreas) == 0 and len(darknessAreas) > 0
