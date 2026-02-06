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


#region On Ready Variables
## Reference to the camera pivot for rotations.
@onready var cameraPivot: Node3D = %CameraPivot
## Reference to the player sprite pivot for asset rotations.
@onready var spritePivot: Node3D = %SpritePivot
## Reference to the player sprite.
@onready var sprite: MeshInstance3D = %Sprite
## Reference to the camera post processing effects.
@onready var postProcessing: Node3D = %PostProcessing
## Reference to the [PickupHandler], the player's grab area.
@onready var grabArea: PickupHandler = %GrabArea
## Reference to the character animation player.
@onready var animationPlayer: AnimationPlayer = %AnimationPlayer
## Reference to the poof particle emitter.
@onready var poof: MultipleParticle3DEmitter = %Poof
## Reference to the poof sound player.
@onready var poofSound: RandomSoundPlayer = %PoofSound
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
## Reference to the darkness blocker module.
@onready var darknessBlockerModule: DarknessBlockerModule = %DarknessBlockerModule
## Reference to the camera.
@onready var cameraCubeWallCutout: Marker3D = %CameraCubeWallCutout
## Reference to cool sticker sprite.
@onready var coolSticker: Sprite3D = %CoolSticker
## Reference to cool sticker shine.
@onready var shine: MeshInstance3D = %Shine
#endregion

#region Variables
## Input axis for movement.
var inputDirection: Vector3 = Vector3.ZERO
## Actual movement direction.
var moveDirection: Vector3 = Vector3.ZERO
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
## Flag for when the player camera is zooming.
var zooming: bool = false
## Flag for when the player camera is zoomed out.
var zoomedOut: bool = false
## Flag for when the reset popup is being popped out
var resetPoppingOut: bool = false
## Reference to the current gridmap.
var gridmap: GridMap
## Flag to stop player input in settings.
var onSettings: bool = false
## Currently fell distance.
var fellDistance: float = 0.0
## Flag to stop the player gravity when forced
var forcedNoGravity: bool = false
## Flag that is true when the player is jumping
var jumping: bool = false
## Flag that is true while the cool sticker animation is playing
var coolStickerGrabbing: bool = false
## Flag that is true when the cool sticker animation is finished
var coolStickerGrabbingFinished: bool = false
## Current cool sticker.
var currentCoolSticker: PocketSticker
#endregion

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.is_editor_hint(): return
	if not get_tree().get_first_node_in_group("SceneManager"): noMovement = false
	#poof.emit_particles()
	cameraPivot.rotation.y = rotation.y
	cameraPivot.global_position = global_position
	material = sprite.get_surface_override_material(0)
	submaterial = sprite.get_surface_override_material(0).next_pass
	if not get_tree().debug_collisions_hint:
		postProcessing.show()
	playerHighlight.scale = Vector3.ONE * 0.001
	while not gridmap:
		gridmap = get_tree().get_first_node_in_group("Gridmap")
		await get_tree().process_frame
	cutout_cube_rotation_check(cameraPivot.rotation.y)

## Handles player input.
func _unhandled_input(_event: InputEvent) -> void:
	if Engine.is_editor_hint(): return
	if onSettings: return
	if coolStickerGrabbing and coolStickerGrabbingFinished:
		if not animationPlayer.current_animation == "CoolSticker_Idle": return
		animationPlayer.play("CoolSticker_End")
		await animationPlayer.animation_finished
		coolStickerGrabbing = false
		coolStickerGrabbingFinished = false
		enable_inputs()
		animation_check()
		return
	if noMovement or zooming: 
		inputDirection = Vector3.ZERO
		return
	inputDirection = Vector3(Input.get_action_strength("right") - Input.get_action_strength("left"), 0.0, Input.get_action_strength("backwards") - Input.get_action_strength("forwards"))
	if Input.is_action_just_pressed("pause"):
		if not PopupManager.is_popup("Settings"):
			onSettings = true
			PopupManager.show_popup("Settings")
			GeneralVariables.inventory.book.show_book()
	check_movement_animation(inputDirection)
	sprite_flip_check()
	camera_rotation_check()
	camera_zoom_check()

## Called during the physics processing step of the main loop.
func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	if onSettings: return
	# Camera Follow
	cameraPivot.global_position = lerp(cameraPivot.global_position, global_position, cameraFollowSpeed)
	move_character(delta)
	animation_check()
	current_grid_check()
	grabArea.canDrop = is_on_floor()

## Blocks the player input control.
func block_inputs() -> void:
	noMovement = true
	grabArea.canGrab = false

## Returns input control to the player.
func enable_inputs() -> void:
	noMovement = false
	grabArea.canGrab = true

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
	cubeCutout.rotatingCamera = true
	currentCameraRotation += cameraRotation
	cutout_cube_rotation_check(cameraPivot.rotation.y + cameraRotation)
	await get_tree().physics_frame
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
	cubeCutout.rotatingCamera = false

## Checks and handles the camera zoom.
func camera_zoom_check() -> void:
	if zooming: return
	var doZoom: bool = Input.is_action_just_pressed("zoom") or (zoomedOut and inputDirection.length() > 0)
	#if not zoomedOut and inputDirection != Vector3.ZERO: doZoom = false
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
	while not gridmap:
		gridmap = get_tree().get_first_node_in_group("Gridmap")
	var currentGridPosition: Vector3 = get_grid_position()
	var pushOnPerpendicularCamera: Vector3 = (Vector3(-0.5, 0.0, -0.5).rotated(Vector3.UP, currentCameraRotation).normalized() / 2.0) if fmod(currentCameraRotation, PI / 2) != 0 else (Vector3.FORWARD * sqrt(2.0)).rotated(Vector3.UP, currentCameraRotation)
	cubeCutoutPivot.global_position = currentGridPosition + pushOnPerpendicularCamera

## Returns the position of the grid cell the player is in.
func get_grid_position() -> Vector3:
	return Vector3(gridmap.local_to_map(global_position - gridmap.global_position)) * gridmap.cell_size + gridmap.global_position + gridmap.cell_size / 2.0

## Gets the inputted player movement.
func get_move_direction() -> Vector3:
	moveDirection = inputDirection
	moveDirection = moveDirection.rotated(Vector3.UP, rotation.y)
	moveDirection = moveDirection.rotated(Vector3.UP, currentCameraRotation)
	return moveDirection

## Moves the player character.
func move_character(delta: float) -> void:
	get_move_direction()
	var pushForce: Vector3 = involuntaryPushModule.get_current_push()
	if not jumping: 
		if moveDirection != Vector3.ZERO:# and (moved < movementMaximum or disableMaximum):
			lastVoluntarySpeed += (moveDirection * acceleration) * delta
			lastVoluntarySpeed = lastVoluntarySpeed.limit_length(maxSpeed)
		else:
			lastVoluntarySpeed = lastVoluntarySpeed.lerp(Vector3.ZERO, decceleration * delta)
		if involuntaryPushModule.blockingMovement > 0 and not is_on_wall():
			lastVoluntarySpeed = Vector3.ZERO
	var movedAmount = (get_last_motion() * Vector3(1.0, 0.0, 1.0)).length()
	if movedAmount != 0:
		MusicManager.set_synchro_clip_volume("main", [1], 0.0, STEPSOUNDTWEENTIME)
	else:
		MusicManager.set_synchro_clip_volume("main", [1], -60.0, STEPSOUNDTWEENTIME)
	lastInvoluntarySpeed -= lastPushForce
	if not is_on_floor() and len(noGravityZones) == 0 and not forcedNoGravity:
		lastInvoluntarySpeed.y -= gravity * delta
		fallSoundPlayed = false
	elif not jumping:
		lastInvoluntarySpeed.y = 0
	lastPushForce = pushForce * delta
	lastInvoluntarySpeed = lastInvoluntarySpeed + lastPushForce
	var floorCheck: bool = false
	var lastY: float = global_position.y
	if (pushForce.length() > 0 or len(noGravityZones) > 0) and currentState != States.Float: 
		currentState = States.Float
	if pushForce.length() == 0 and currentState == States.Float and len(noGravityZones) == 0:
		currentState = States.Idle
		animation_check()
	if currentState == States.Float and (pushForce * Vector3(1.0, 0.0, 1.0)).length() > 0: floorCheck = true
	velocity = lastInvoluntarySpeed + lastVoluntarySpeed
	move_and_slide()
	if floorCheck and global_position.y < lastY:
		global_position.y = lastY
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

## Checks for required animation state changes.
func check_movement_animation(currentInputDirection: Vector3) -> void:
	if currentState != States.Float: currentState = States.Walk if currentInputDirection.length() > 0 else States.Idle
	if currentInputDirection.z == 0 and currentState != States.Idle: return
	facingBack = currentInputDirection.z < 0

## Switches player animation state.
func animation_check() -> void:
	if coolStickerGrabbing: return
	var newAnimationName = ("Grab_" if grabArea.pickupOnHand else "") + States.keys()[currentState] as String + ("_Back" if facingBack else "")
	if newAnimationName != currentAnimation:
		animationPlayer.play(newAnimationName)
		currentAnimation = newAnimationName

## Do cool sticker animation.
func grabbed_inventory_sticker(sticker: PocketSticker) -> void:
	currentCoolSticker = sticker
	coolSticker.texture = sticker.image
	var shineMaterial: ShaderMaterial = shine.get_surface_override_material(0)
	shineMaterial.set_shader_parameter("gradientColor", sticker.glowBackgroundColor)
	shineMaterial.set_shader_parameter("rayColor", sticker.glowRay1Color)
	shineMaterial.set_shader_parameter("secondRayColor", sticker.glowRay2Color)
	animationPlayer.play("CoolSticker")
	coolStickerGrabbing = true
	block_inputs()
	# Reemplazar por un wait para la musiquita
	await get_tree().create_timer(2).timeout
	coolStickerGrabbingFinished = true

## Store cool sticker.
func store_cool_sticker() -> void:
	if not currentCoolSticker: return
	GeneralVariables.inventory.add_sticker(currentCoolSticker)
	currentCoolSticker = null

## External forces functions
#region External Forces
## Adds a no gravity zone to the noGravityZones list
func enter_no_gravity(node: Node3D) -> void:
	if not noGravityZones.has(node): noGravityZones.append(node)

## Removes a no gravity zone from the noGravityZones list
func exit_no_gravity(node: Node3D) -> void:
	noGravityZones.erase(node)
#endregion

#region On Player Sticker Functions
## Returns true if not on the floor or floating
func check_falling() -> bool:
	var falling: bool = false
	if not is_on_floor() and (not forcedNoGravity or len(noGravityZones) == 0):
		falling = true
	else:
		falling = false
	return falling
#endregion
