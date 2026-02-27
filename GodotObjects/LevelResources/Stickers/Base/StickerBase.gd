@tool
extends CharacterBody3D
## The basic sticker skeleton.
class_name StickerBase

## Signals that the sticker was placed or removed
signal just_placed(bool)

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
## Maximum preplaced distance check.
const MAXPREPLACEDDISTANCE: float = 1.0

## State of the sticker.
enum ScaleModes {GRABBED, DROPPED, PLACED, ZOOMEDOUT}

## If true checks for areas to place after loading.
@export var placed: bool = false
## Group to hide storage only variables because export storage doesn't seem to do the thing.
@export_group("Root Reference")
## Parent node reference for placement.
@export var sceneParent: Node
## Original parent node reference for saves.
@export var originalParent: String

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
## The path for the scene this node whas picked up from
var originalParentPath: String
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
## Has this sticker been created by a save.
var isSaveCreated: bool = false
## This node's UUID.
var UUID: int
## Has this node been moved by the player.
var hasBeenMoved: bool = false
## Area to get scene parent.
var parentChecker: Area3D
## Has been moved.
var moved: bool = false
## Placed particles.
var placedParticles: MultipleParticle3DEmitter

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.is_editor_hint():
		var testSceneParent = get_tree().edited_scene_root
		if testSceneParent.has_node("Player"): return
		sceneParent = testSceneParent
		originalParent = sceneParent.name
		return
	if self is not InventorySticker:
		parentChecker = %ParentChecker
		placedParticles = %StickedPlacedParticles
	collisionMask = collision_mask
	meshMaterial = mesh.get_surface_override_material(0).duplicate(true)
	mesh.set_surface_override_material(0, meshMaterial)
	mesh.mesh = mesh.mesh.duplicate()
	backMaterial = back.get_surface_override_material(0).duplicate()
	back.set_surface_override_material(0, backMaterial)
	startSize = mesh.mesh.size
	shadowDecal.size = Vector3(BOBBINGSCALE, shadowDecal.size.y, BOBBINGSCALE)
	prerender()
	get_tree().get_first_node_in_group("Player").zooming_out.connect(zooming_out)
	areaChecker.area_entered.connect(_on_area_entered)
	areaChecker.area_exited.connect(_on_area_exited)
	await get_tree().create_timer(PLACEDCHECKTIME).timeout
	check_placement()
	lastLocation = global_position
	lastMode = placed
	if not isSaveCreated:
		UUID = get_instance_id()
		originalParentPath = get_path().slice(1)

## Checks for nearby areas to place itself
func check_placement() -> void:
	if not placed: 
		set_size(ScaleModes.DROPPED)
		set_deferred("collision_mask", collisionMask)
	else:
		while not GeneralVariables.stickerableSurfacesManager:
			await get_tree().process_frame
		var mainScene: Node = get_tree().get_first_node_in_group("Player").get_parent()
		mainScene = mainScene.get_child(mainScene.get_child_count() - 1)
		if not mainScene.is_node_ready():
			await mainScene.ready
		await get_tree().process_frame
		await get_tree().process_frame
		var closest: StickerableSurfaceData = GeneralVariables.stickerableSurfacesManager.get_closest_valid_surface(global_position, self)
		if closest != null: 
			if closest.globalPosition.distance_to(global_position) <= MAXPREPLACEDDISTANCE: 
				place_sticker(closest.globalPosition, closest.direction, closest.specialScale, closest.specialFlags)
				closest.used = self
				closest.node.sticker_activity()
				return
		set_size(ScaleModes.DROPPED)
		set_deferred("collision_mask", collisionMask)
		placed = false

## Executed on every physics frame.
func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint(): 
		var testSceneParent = get_tree().edited_scene_root
		if testSceneParent == sceneParent: return
		if testSceneParent.has_node("Player"): return
		sceneParent = testSceneParent
		originalParent = sceneParent.name
		return
	if placed or grabed: return
	var currentPush: Vector3 = involuntaryPushModule.get_current_push()
	velocity = currentPush * delta
	move_and_slide()
	if currentPush.length() > 0:
		moved = true
	elif moved:
		if len(parentChecker.get_overlapping_bodies()) == 0: return
		await do_reparent()
		_push_save()
		moved = false

## Cabeza fix to load visuals
func prerender() -> void:
	billboardZoomedOut.no_depth_test = false
	billboardZoomedOut.fixed_size = false
	var zoomsize = billboardZoomedOut.pixel_size
	billboardZoomedOut.pixel_size = 0.0001
	var billboardsize = billboard.pixel_size
	billboard.pixel_size = 0.0001
	mesh.show()
	back.show()
	billboard.show()
	billboardZoomedOut.show()
	await get_tree().physics_frame
	mesh.hide()
	back.hide()
	billboard.hide()
	billboardZoomedOut.hide()
	await get_tree().physics_frame
	mesh.show()
	back.show()
	billboard.show()
	billboardZoomedOut.show()
	await get_tree().physics_frame
	billboard.hide()
	billboardZoomedOut.hide()
	billboardZoomedOut.no_depth_test = true
	billboardZoomedOut.fixed_size = true
	billboardZoomedOut.pixel_size = zoomsize
	billboard.pixel_size = billboardsize

## Places the sticker on the given area facing the given direction
func place_sticker(pos: Vector3, direction: Vector3, overrideSize: Vector3 = Vector3.ONE, _specialFlags: int = 0) -> void:
	if not Vector3.UP.cross(direction).is_zero_approx():
		look_at(global_position - direction)
	else:
		look_at(global_position - direction, Vector3.FORWARD)
	set_size(ScaleModes.PLACED)
	meshes.scale = overrideSize
	placedPosition = pos
	global_position = pos + direction * 0.01
	placed = true
	just_placed.emit(placed)
	grabed = false
	await do_reparent(pos + direction * 0.01)
	if hasBeenMoved:
		_push_save()
	if not placed or not is_inside_tree(): return

## Changes the current state and visuals to the given mode
func set_size(mode: ScaleModes) -> void:
	if mode != ScaleModes.ZOOMEDOUT: lastVisualMode = mode
	match mode:
		ScaleModes.GRABBED:
			stop_rotation()
			billboard.show()
			mesh.hide()
			back.hide()
			billboardZoomedOut.hide()
		ScaleModes.DROPPED:
			billboard.hide()
			mesh.show()
			back.show()
			billboardZoomedOut.hide()
			meshes.scale = Vector3.ONE * BOBBINGSCALE
			start_rotation()
		ScaleModes.PLACED:
			stop_rotation()
			billboard.hide()
			mesh.show()
			back.show()
			billboardZoomedOut.hide()
			meshes.scale = Vector3.ONE
			if placedParticles and hasBeenMoved: placedParticles.emit_particles()
		ScaleModes.ZOOMEDOUT:
			stop_rotation()
			billboardZoomedOut.show()
			billboard.hide()
			mesh.hide()
			back.hide()
			meshes.scale = Vector3.ONE * ZOOMOUTSCALE

## Moves the sticker position to the given node position.
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
	just_placed.emit(placed)
	GeneralVariables.saveManager.delete_sticker(self)
	hasBeenMoved = true

## Called when player reset is called.
func reset_sticker() -> void:
	await do_reparent()
	grabed = false
	global_position = lastLocation
	placed = lastMode
	just_placed.emit(placed)
	check_placement()

## Special reparent for scene loading workaround
func do_reparent(newPos: Vector3 = global_position) -> void:
	sceneParent = null
	while sceneParent == null:
		var bodies: Array[Node3D] = parentChecker.get_overlapping_bodies()
		bodies.sort_custom(func(a: Node3D, b: Node3D): return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position))
		if len(bodies) == 0: await get_tree().process_frame
		else: 
			sceneParent = get_root_parent(bodies[0])
			await get_tree().process_frame
	reparent(sceneParent)
	global_position = newPos

## Special recursive check to get root scene.
func get_root_parent(node: Node) -> Node:
	var tempParent: Node = node.get_parent()
	if not tempParent: return null
	if tempParent.has_meta("isRoot"):
		return tempParent
	else:
		return get_root_parent(tempParent)

## Drops the sticker on the ground reparenting it to the scene
func drop() -> void:
	set_deferred("collision_mask", collisionMask)
	set_size(ScaleModes.DROPPED)
	global_position.y = global_position.y - GRABHEIGHT
	placed = false
	just_placed.emit(placed)
	await do_reparent()
	grabed = false
	_push_save()

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
			set_size(ScaleModes.ZOOMEDOUT)
		else: 
			set_size(lastVisualMode)

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

## Saves modifications to this sticker
func _push_save() -> void:
	GeneralVariables.saveManager.store_change(self, sceneParent)
	hasBeenMoved = true
