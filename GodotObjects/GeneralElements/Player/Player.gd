@tool
extends CharacterBody3D
## The player object.
class_name Player

#region Constants
## How much the camera rotates for each button press.
const CAMERAROTATIONSTEP: float = PI / 4.0
## Camera rotation animation time.
const CAMERALERPDURATION: float = 0.25
## Camera zoom out position.
const CAMERAZOOMOUT: Vector3 = Vector3(0, 5, 7)
## Camera zoom out animation time.
const CAMERAZOOMTIME: float = 0.25
## Time to transparency on restart
const TRANSPARENCYTIME: float = 0.1
## Time to full volume for step drums music.
const STEPSOUNDTWEENTIME: float = 0.25
## Time for reset popup animation.
const POPUPTIME: float = 0.5
## Time to wait after no moves to show the reset popup.
const RESETBUTTONWAIT: float = 1.0
## Time the restart takes.
const PLAYERRESTARTWAITTIME: float = 0.25
## Minimum fall distance to play the fall sound at minimum volume.
const MINFALLDISTANCE: float = 0.75
## Maximum fall distance to play the fall sound at top volume.
const MAXFALLDISTANCE: float = 5.0
## Minimum fall volume.
const MINFALLVOLUME: float = -7.0
## Maximum fall volume.
const MAXFALLVOLUME: float = -5.0
## Minimum fall volume.
const MINFALLPITCH: float = 1.5
## Maximum fall volume.
const MAXFALLPITCH: float = 1.0

## Time it takes for the player sprite to flip.
const spriteFlipDuration: float = 0.5
## The camera follow speed.
const cameraFollowSpeed: float = 0.1

## Character movement speed.
const maxSpeed: float = 3
## Character movement acceleration.
const acceleration: float = 20.0
## Character movement decceleration.
const decceleration: float = 20.0
## Character gravity.
const gravity: float = 32
#endregion

## Signal emmited when camera is zooming in or out.
signal zooming_out(zoomingOut: bool)

## Animation states.
enum States {Idle, Walk, Float}

#region Exports
## How far from the checkpoint the player can travel.
@export_range(0, 100, .1) var movementMaximum: float = 10:
	set(value):
		movementMaximum = value
		if Engine.is_editor_hint(): set_decal_size()
## Player has no traveling limit.
@export var disableMaximum: bool = false:
	set(value):
		disableMaximum = value
		if Engine.is_editor_hint(): set_decal_size()
#endregion

#region On Ready Variables
## Reference to the camera pivot for rotations.
@onready var cameraPivot: Node3D = %CameraPivot
## Reference to the player sprite pivot for asset rotations.
@onready var spritePivot: Node3D = %SpritePivot
## Reference to the player sprite.
@onready var sprite: MeshInstance3D = %Sprite
## Reference to the player area decal. TO BE REIMPLEMENTED.
@onready var lightDecal: Decal = %LightDecal
## Reference to the camera post processing effects.
@onready var postProcessing: MeshInstance3D = %PostProcessing
## Reference to the [PickupHandler], the player's grab area.
@onready var grabArea: PickupHandler = %GrabArea
## Reference to the character animation player.
@onready var animationPlayer: AnimationPlayer = %AnimationPlayer
## Reference to the poof particle emitter.
@onready var poof: MultipleParticle3DEmitter = %Poof
## Reference to the poof sound player.
@onready var poofSound: RandomPitchPlayer = %PoofSound
## Reference to the player shadow decal.
@onready var shadowDecal: Decal = %ShadowDecal
## Reference to the fall sound player.
@onready var fallSound: AudioStreamPlayer = %FallSound
## Reference to the rotate camera left sound player.
@onready var rotateCamLeftSound: AudioStreamPlayer = %RotateCamLeft
## Reference to the rotate camera right sound player.
@onready var rotateCamRightSound: AudioStreamPlayer = %RotateCamRight
## Reference to the zoom camera in sound player.
@onready var camZoomIn: AudioStreamPlayer = %CamZoomIn
## Reference to the camera zoom pivot.
@onready var cameraZoomPivot: Node3D = %CameraZoomPivot
## Reference to the zoom camera out sound player.
@onready var camZoomOut: AudioStreamPlayer = %CamZoomOut
## Reference to the player highlight sprite for zooming out.
@onready var playerHighlight: Sprite3D = %PlayerHighlight
## Reference to the reset message popup sprite.
@onready var message: Sprite3D = %Message
## Reference to the popup sound player.
@onready var popUpSound: RandomPitchPlayer = %PopUpSound
## Reference to the camera cutout cube.
@onready var cubeCutout: CutoutCube = %CubeCutout
## Reference to the camera cutout cube pivot.
@onready var cubeCutoutPivot: Node3D = %CubeCutoutPivot
## The reset popup assets.
@onready var resetAssets: Dictionary[String, Texture2D] = {
	"keyboard": preload("uid://dd8k35t2irrpo"),
	"controller": preload("uid://3pmu7pe3ruii")
}
## Reference to the involuntary movement module.
@onready var involuntaryPushModule: InvoluntaryPushModule = %InvoluntaryPushModule
#endregion

#region Variables
## Input axis for movement.
var inputDirection: Vector3 = Vector3.ZERO
## The rotation of the camera, used for lerping.
var currentCameraRotation: float = 0.0
## The tween used for camera rotation.
var cameraRotationTween: Tween
## The tween used for camera zoom.
var cameraZoomTween: Tween
## The tween used for player flip.
var spriteFlipTween: Tween
## Used to check if sprite should flip.
var lastHorizontal: float = 1
## Whether the sprite is facing backwards.
var facingBack: bool = false
## Accumultation of nogravity areas.
var noGravityZones: Array[Node3D] = []
## How much the player moved after last checkpoint.
var moved: float = 0.0
## Saving last movement distance for distance checking.
var lastVoluntarySpeed: Vector3 = Vector3.ZERO
## Saving last involuntary movement distance for distance checking.
var lastInvoluntarySpeed: Vector3 = Vector3.ZERO
## Saving last involuntary push force for distance checking.
var lastPushForce: Vector3 = Vector3.ZERO
## Current animation state
var currentState: States = States.Idle
## Current full animation string.
var currentAnimation: String = "Idle"
## Tween used to fade the player out.
var transparencyTween: Tween
## Has spawned flag to avoid soudns and effects and spawn.
var hasSpawned: bool = false
## Reference to the player material for animations.
var material: StandardMaterial3D
## Reference to the player submaterial for animations.
var submaterial: StandardMaterial3D
## Flag for stopping the player input.
var noMovement: bool = true
## Flag for playing falling sound only once. NEEDS TO BE REWORKED TO USE FALLING DISTANCE THRESHOLDS.
var fallSoundPlayed: bool = false
## Flag to notify if the current fall is due to respawning.
var respawnFall: bool = true
## The tween used to popup the reset message.
var popupTween: Tween
## Flag for when the player has exceeded their movement limit.
var stopped: bool = false
## Flag for when the player camera is zooming.
var zooming: bool = false
## Flag for when the player camera is zoomed out.
var zoomedOut: bool = false
## Flag for when the player is inside a checkpoint area.
var inCheckpoint: bool = true
## Flag for when the reset popup is being popped out
var resetPoppingOut: bool = false
## Reference to the current gridmap.
var gridmap: GridMap
## Current position to respawn to.
var currentCheckpointPosition: Vector3
## Flag to stop player input in settings.
var onSettings: bool = false
## Flag for when the player is respawning.
var respawning: bool = false
## Currently fell distance.
var fellDistance: float = 0.0
## OnPlayerEffect node reference.
var onPlayerEffectRef: OnPlayerFan
#endregion

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.is_editor_hint(): return
	if not get_tree().get_first_node_in_group("SceneManager"): noMovement = false
	set_decal_size()
	poof.emit_particles()
	cameraPivot.rotation.y = rotation.y
	cameraPivot.global_position = global_position
	material = sprite.get_surface_override_material(0)
	submaterial = sprite.get_surface_override_material(0).next_pass
	postProcessing.show()
	playerHighlight.scale = Vector3.ONE * 0.001
	GeneralVariables.input_mode_changed.connect(control_scheme_switch)
	control_scheme_switch(GeneralVariables.usingGamepad)
	while not gridmap:
		gridmap = get_tree().get_first_node_in_group("Gridmap")
		await get_tree().process_frame
	cutout_cube_rotation_check(cameraPivot.rotation.y)

## Handles player input.
func _unhandled_input(_event: InputEvent) -> void:
	if Engine.is_editor_hint(): return
	if onSettings: return
	if noMovement or zooming: 
		inputDirection = Vector3.ZERO
		return
	inputDirection = Vector3(Input.get_action_strength("right") - Input.get_action_strength("left"), 0.0, Input.get_action_strength("backwards") - Input.get_action_strength("forwards"))
	if Input.is_action_just_pressed("reset_player") and not noMovement:
		restart_at_checkpoint()
		return
	if Input.is_action_just_pressed("pause"):
		onSettings = true
		PopupManager.show_popup("Settings")
	check_movement_animation(inputDirection)
	sprite_flip_check()
	camera_rotation_check()
	camera_zoom_check()

## Called during the physics processing step of the main loop.
func _physics_process(delta: float) -> void:
	if onSettings: return
	# Camera Follow
	cameraPivot.global_position = lerp(cameraPivot.global_position, global_position, cameraFollowSpeed)
	if Engine.is_editor_hint(): return
	move_character(delta)
	animation_check()
	current_grid_check()
	grabArea.canDrop = is_on_floor()
	if not stopped:
		if not resetPoppingOut: do_popout()
		if popupTween:
			popupTween.kill()
		message.scale = Vector3.ONE * 0.001

## Blocks the player input. RIGHT NOW ONLY USED IN GOAL AREA.
func block_inputs() -> void:
	noMovement = true
	grabArea.canGrab = false

## Checks and handles flipping the character sprite.
func sprite_flip_check() -> void:
	var horizontal: float = sign(Input.get_action_strength("right") - Input.get_action_strength("left"))
	if horizontal == 0.0: return
	if lastHorizontal != horizontal:
		if spriteFlipTween: 
			if spriteFlipTween.is_running(): 
				await spriteFlipTween.finished
				horizontal = sign(Input.get_action_strength("right") - Input.get_action_strength("left"))
				if lastHorizontal == horizontal or horizontal == 0: return
		spriteFlipTween = create_tween()
		spriteFlipTween.tween_method(
			func(rotationValue: float): sprite.rotation.y = rotationValue,
			sprite.rotation.y,
			0.0 if horizontal == 1 else deg_to_rad(180),
			spriteFlipDuration
		).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)
		spriteFlipTween.play()
	lastHorizontal = horizontal

## Checks and handles rotating the camera.
func camera_rotation_check() -> void:
	if cameraRotationTween: return
	var cameraRotation: float = (CAMERAROTATIONSTEP if Input.is_action_just_pressed("camera_right") else 0.0) - (CAMERAROTATIONSTEP if Input.is_action_just_pressed("camera_left") else 0.0)
	if cameraRotation == 0: return
	currentCameraRotation += cameraRotation
	cutout_cube_rotation_check(cameraPivot.rotation.y + cameraRotation)
	cameraRotationTween = create_tween()
	cameraRotationTween.tween_method(
		func(rotationValue: float): 
			spritePivot.rotation.y = rotationValue
			cameraPivot.rotation.y = rotationValue + rotation.y,
		spritePivot.rotation.y,
		currentCameraRotation,
		CAMERALERPDURATION
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	cameraRotationTween.finished.connect(camera_rotation_finished)
	cameraRotationTween.play()
	if cameraRotation > 0:
		rotateCamLeftSound.play()
	else:
		rotateCamRightSound.play()

## Called when the camera finishes rotating.
func camera_rotation_finished() -> void:
	if fmod(currentCameraRotation, deg_to_rad(360.0)) == 0.0: 
		currentCameraRotation = 0.0
		spritePivot.rotation.y = 0.0
		cameraPivot.rotation.y = rotation.y
	if cameraRotationTween: 
		cameraRotationTween.kill()
		cameraRotationTween = null

## Checks and handles the camera zoom.
func camera_zoom_check() -> void:
	if zooming: return
	var doZoom: bool = Input.is_action_just_pressed("zoom") or (zoomedOut and inputDirection.length() > 0)
	if not doZoom: return
	cubeCutout.zoomedOut = not zoomedOut
	zooming_out.emit(not zoomedOut)
	if zoomedOut: camZoomIn.play()
	else: camZoomOut.play()
	zooming = true
	noMovement = true
	grabArea.canGrab = false
	cameraZoomTween = create_tween()
	cameraZoomTween.tween_property(cameraZoomPivot, "position", CAMERAZOOMOUT if not zoomedOut else Vector3.ZERO, CAMERAZOOMTIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	cameraZoomTween.parallel().tween_property(playerHighlight, "scale", (Vector3.ONE * 0.001) if zoomedOut else Vector3.ONE, CAMERAZOOMTIME).set_trans(Tween.TRANS_SINE)
	cameraZoomTween.play()
	await cameraZoomTween.finished
	zooming = false
	noMovement = false
	grabArea.canGrab = true
	zoomedOut = not zoomedOut
	grabArea.zoomedOut = zoomedOut

## Checks and handles the cutout cube rotation.
func cutout_cube_rotation_check(rotationCheck: float) -> void:
	if fmod(abs(rotationCheck) + 0.0001, PI / 2.0) < 0.001:
		cubeCutout.auxMode = false
		cubeCutoutPivot.rotation.y = rotationCheck
	else: 
		cubeCutout.auxMode = true
		cubeCutoutPivot.rotation.y = rotationCheck - PI / 4.0

## Checks and handles the cutout cube snapping to the gridmap.
func current_grid_check() -> void:
	if not gridmap: return
	var currentGridPosition: Vector3 = Vector3(gridmap.local_to_map(global_position - gridmap.global_position)) * gridmap.cell_size + gridmap.global_position + gridmap.cell_size / 2.0
	var pushOnPerpendicularCamera: Vector3 = (Vector3(-0.5, 0.0, -0.5).rotated(Vector3.UP, currentCameraRotation).normalized() / 2.0) if fmod(currentCameraRotation, PI / 2) != 0 else (Vector3.FORWARD * sqrt(2.0)).rotated(Vector3.UP, currentCameraRotation)
	cubeCutoutPivot.global_position = currentGridPosition + pushOnPerpendicularCamera

## Gets the inputted player movement.
func get_move_direction() -> Vector3:
	var moveDirection: Vector3 = inputDirection
	moveDirection = moveDirection.rotated(Vector3.UP, rotation.y)
	moveDirection = moveDirection.rotated(Vector3.UP, currentCameraRotation)
	return moveDirection

## Moves the player character.
func move_character(delta: float) -> void:
	var moveDirection: Vector3 = get_move_direction()
	var pushForce: Vector3 = involuntaryPushModule.get_current_push()
	if moved >= movementMaximum and not stopped and not disableMaximum:
		do_popup()
		stopped = true
	if moveDirection != Vector3.ZERO and (moved < movementMaximum or disableMaximum):
		lastVoluntarySpeed += (moveDirection * acceleration) * delta
		lastVoluntarySpeed = lastVoluntarySpeed.limit_length(maxSpeed)
	else:
		lastVoluntarySpeed = lastVoluntarySpeed.lerp(Vector3.ZERO, decceleration * delta)
	velocity = lastVoluntarySpeed
	move_and_slide()
	var movedAmount = (get_last_motion() * Vector3(1.0, 0.0, 1.0)).length()
	if movedAmount != 0:
		MusicManager.set_synchro_clip_volume("main", [1], 0.0, STEPSOUNDTWEENTIME)
	else:
		MusicManager.set_synchro_clip_volume("main", [1], -60.0, STEPSOUNDTWEENTIME)
	if not inCheckpoint: moved += movedAmount
	set_decal_size()
	lastInvoluntarySpeed -= lastPushForce
	if not is_on_floor() and len(noGravityZones) == 0:
		lastInvoluntarySpeed.y -= gravity * delta
		fallSoundPlayed = false
	else:
		lastInvoluntarySpeed.y = 0
	lastPushForce = pushForce * delta
	lastInvoluntarySpeed = (lastInvoluntarySpeed + lastPushForce) if not respawning else Vector3.ZERO
	if (pushForce.length() > 0 or len(noGravityZones) > 0) and currentState != States.Float: currentState = States.Float
	if pushForce.length() == 0 and currentState == States.Float and len(noGravityZones) == 0:
		currentState = States.Idle
		animation_check()
	velocity = lastInvoluntarySpeed
	move_and_slide()
	if not is_on_floor():
		fellDistance += (get_last_motion() * Vector3.UP).length()
	else: 
		play_fall_sound()
		fellDistance = 0
	if is_on_floor() and respawnFall:
		respawnFall = false
		fallSoundPlayed = true
	fallSoundPlayed = true

## Plays falling sound
func play_fall_sound() -> void:
	if fallSoundPlayed or respawnFall or fellDistance < MINFALLDISTANCE: return
	fallSound.pitch_scale = lerpf(MINFALLPITCH, MAXFALLPITCH, min(1.0, inverse_lerp(MINFALLDISTANCE, MAXFALLDISTANCE, fellDistance)))
	fallSound.volume_db = lerpf(MINFALLVOLUME, MAXFALLVOLUME, min(1.0, inverse_lerp(MINFALLDISTANCE, MAXFALLDISTANCE, fellDistance)))
	fallSound.play()

## Sets the movement area decal size to match the expected size.
func set_decal_size() -> void:
	if Engine.is_editor_hint() and not lightDecal: return
	while not lightDecal:
		await get_tree().process_frame
	if disableMaximum:
		if lightDecal: lightDecal.hide()
		return
	else: lightDecal.show()
	lightDecal.size.x = (movementMaximum - moved) * 2.0
	lightDecal.size.z = lightDecal.size.x

## Resets the player movement limit.
func reset_aura() -> void:
	moved = 0
	set_decal_size()

## Restarts player at last checkpoint.
func restart_at_checkpoint() -> void:
	respawnFall = true
	respawning = true
	if not hasSpawned:
		global_position = currentCheckpointPosition
		reset_aura()
		hasSpawned = true
		await get_tree().process_frame
		await get_tree().physics_frame
		get_tree().call_group("Checkpoints","enable_sounds")
		respawning = false
		return
	do_popout()
	noMovement = true
	grabArea.canGrab = false
	poofSound.play_sound()
	if transparencyTween:
		transparencyTween.kill()
	transparencyTween = create_tween()
	transparencyTween.tween_property(material, "albedo_color:a", 0.0, TRANSPARENCYTIME)
	transparencyTween.parallel().tween_property(submaterial, "albedo_color:a", 0.0, TRANSPARENCYTIME)
	transparencyTween.parallel().tween_property(shadowDecal, "modulate:a", 0.0, TRANSPARENCYTIME)
	transparencyTween.play()
	poof.emit_particles(global_position, sprite.global_rotation)
	lastInvoluntarySpeed = Vector3.ZERO
	lastPushForce = Vector3.ZERO
	noGravityZones.clear()
	involuntaryPushModule.clear()
	await get_tree().create_timer(PLAYERRESTARTWAITTIME).timeout
	global_position = currentCheckpointPosition
	reset_aura()
	poof.emit_particles(global_position, sprite.global_rotation)
	if transparencyTween:
		transparencyTween.kill()
	transparencyTween = create_tween()
	transparencyTween.tween_property(material, "albedo_color:a", 1.0, TRANSPARENCYTIME)
	transparencyTween.parallel().tween_property(submaterial, "albedo_color:a", 1.0, TRANSPARENCYTIME)
	transparencyTween.parallel().tween_property(shadowDecal, "modulate:a", 1.0, TRANSPARENCYTIME)
	transparencyTween.play()
	await get_tree().create_timer(PLAYERRESTARTWAITTIME).timeout
	noMovement = false
	grabArea.canGrab = true
	stopped = false
	respawning = false

## Checks for required animation state changes.
func check_movement_animation(currentInputDirection: Vector3) -> void:
	if currentState != States.Float: currentState = States.Walk if currentInputDirection.length() > 0 else States.Idle
	if currentInputDirection.z == 0 and currentState != States.Idle: return
	facingBack = currentInputDirection.z < 0

## Switches player animation state.
func animation_check() -> void:
	var newAnimationName = ("Grab_" if grabArea.pickupOnHand else "") + States.keys()[currentState] as String + ("_Back" if facingBack else "")
	if newAnimationName != currentAnimation:
		animationPlayer.play(newAnimationName)
		currentAnimation = newAnimationName

## Handle showing, hiding, and modifying reset popup.
#region Reset Popup Functions
## Shows the reset popup.
func do_popup() -> void:
	resetPoppingOut = false
	await get_tree().create_timer(RESETBUTTONWAIT).timeout
	if not stopped: return
	if popupTween:
		popupTween.kill()
	popupTween = create_tween()
	popupTween.tween_property(message, "scale", Vector3.ONE, POPUPTIME * (1.0 - message.scale.x)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	popupTween.play()
	popUpSound.play_sound()

## Hides the reset popup.
func do_popout() -> void:
	if popupTween:
		popupTween.kill()
	resetPoppingOut = true
	popupTween = create_tween()
	popupTween.tween_property(message, "scale", Vector3.ONE * 0.001, POPUPTIME * message.scale.x).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	popupTween.play()
	popupTween.finished.connect(set.bind("resetPoppingOut", false))

## Switches reset poupup sprite to match control scheme.
func control_scheme_switch(isController: bool) -> void:
	if isController: message.texture = resetAssets.controller
	else: message.texture = resetAssets.keyboard
#endregion

## Handle entering and exiting checkpoints.
#region Checkpoint Area Functions
## Handle entering a checkpoint.
func checkpoint_entered() -> void:
	inCheckpoint = true
	moved = 0

## Handle exiting a checkpoint.
func checkpoint_exited() -> void:
	inCheckpoint = false
#endregion

## External forces functions
#region External Forces
## Adds a no gravity zone to the noGravityZones list
func enter_no_gravity(node: Node3D) -> void:
	if not noGravityZones.has(node): noGravityZones.append(node)

## Removes a no gravity zone from the noGravityZones list
func exit_no_gravity(node: Node3D) -> void:
	noGravityZones.erase(node)
#endregion
