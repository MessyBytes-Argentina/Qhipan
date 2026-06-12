@tool
extends CharacterBody3D
## The player object.
class_name Player

#region Constants
## Animation states.
enum States {Idle, Walk, Float, Slap}

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
## Regular animation states with no grab mode.
const NOGRABSTATES: Array[States] = [States.Slap]
## Regular animation states that can't be interrupted.
const NOINTERRUPTSTATES: Array[States] = [States.Slap]
## Fanfare wait times.
const FANFAREWAIT: Dictionary[String, float] = {"pause": 0.1, "unpause": 1.0}
## Maximum player sprite angle.
const MAXSPRITEANGLE: float = deg_to_rad(15)

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
const gravity: float = 20
## Movement speed in the air.
const airMovementMultiplier: float = 0.35

## Camera animation time on coolsticker.
const CAMERALERPCOOLSTICKER: float = 0.3
#endregion

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
## Reference to the fall sound player.
@onready var fallSound: AudioStreamPlayer = %FallSound
## Reference to the camera.
@onready var camera: Camera3D = %Camera3D
## The reset popup assets.
@onready var resetAssets: Dictionary[String, Texture2D] = {
	"keyboard": preload("uid://dd8k35t2irrpo"),
	"controller": preload("uid://3pmu7pe3ruii")
}
## Reference to the involuntary movement module.
@onready var involuntaryPushModule: InvoluntaryPushModule = %InvoluntaryPushModule
## Reference to the darkness blocker module.
@onready var darknessBlockerModule: DarknessBlockerModule = %DarknessBlockerModule
## Reference to cool sticker sprite.
@onready var coolSticker: Sprite3D = %CoolSticker
## Reference to cool sticker shine.
@onready var shine: MeshInstance3D = %Shine
## Reference to the alternator held effect.
@onready var alternatorHeldEffect: MeshInstance3D = %AlternatorHeldEffect
## Reference to the fanfare sound.
@onready var fanfare: AudioStreamPlayer = %Fanfare
## Ledge detection.
@onready var ledgeDetection: LedgeDetection = $LedgeDetection
## Camera probe for darkness cutout.
@onready var cameraProbe: Node3D = %CameraProbe
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
var facingBack: float = 0
## Last facing direction.
var lastFacingBack: bool = false
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
## Flag for rotating camera.
var rotatingCamera: bool = false
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
## Used for input and rotation mapping.
var currentCamera: Camera3D
## Used to remember camera.
var previousCamera: Camera3D
#endregion

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.is_editor_hint(): return
	grabArea.player = self
	if not get_tree().get_first_node_in_group("SceneManager"): noMovement = false
	material = sprite.get_surface_override_material(0)
	submaterial = sprite.get_surface_override_material(0).next_pass
	if not get_tree().debug_collisions_hint:
		postProcessing.show()
	while not gridmap:
		gridmap = get_tree().get_first_node_in_group("Gridmap")
		await get_tree().process_frame
	## BULLSHIT FOR THE DEMO
	GeneralVariables.inventory.book.get_parent().show()
	GeneralVariables.in_game_switch(true)

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
		CameraLerper.switch_to(previousCamera, CAMERALERPCOOLSTICKER)
		enable_inputs()
		animation_check()
		return
	if noMovement or zooming: 
		inputDirection = Vector3.ZERO
		return
	inputDirection = Vector3(Input.get_action_strength("right") - Input.get_action_strength("left"), 0.0, Input.get_action_strength("backwards") - Input.get_action_strength("forwards"))
	if Input.is_action_just_pressed("pause"):
		if not PopupManager.is_popup("Settings") and not coolStickerGrabbing:
			onSettings = true
			PopupManager.show_popup("Settings")
			GeneralVariables.inventory.book.show_book()
	check_movement_animation(inputDirection)
	sprite_flip_check()

## Called during the physics processing step of the main loop.
func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	if onSettings: return
	move_character(delta)
	animation_check()
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
	var horizontal: float = sign(Input.get_action_strength("left") - Input.get_action_strength("right"))
	if horizontal == 0.0: return
	if lastHorizontal != horizontal:
		if spriteFlipTween: 
			if spriteFlipTween.is_running(): 
				await spriteFlipTween.finished
				horizontal = sign(Input.get_action_strength("left") - Input.get_action_strength("right"))
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

## Returns the position of the grid cell the player is in.
func get_grid_position() -> Vector3:
	return Vector3(gridmap.local_to_map(global_position - gridmap.global_position)) * gridmap.cell_size + gridmap.global_position + gridmap.cell_size / 2.0

## Gets the inputted player movement.
func get_move_direction() -> Vector3:
	moveDirection = inputDirection
	if currentCamera and currentCamera != camera:
		currentCameraRotation = currentCamera.global_rotation.y
		spritePivot.look_at(currentCamera.global_position, currentCamera.global_transform.basis.y)
		spritePivot.rotation.x = clamp(spritePivot.rotation.x, -MAXSPRITEANGLE, MAXSPRITEANGLE)
		spritePivot.rotation.z = clamp(spritePivot.rotation.z, -MAXSPRITEANGLE, MAXSPRITEANGLE)
		moveDirection = moveDirection.rotated(Vector3.UP, currentCameraRotation).normalized()
		cameraPivot.global_rotation.y = currentCameraRotation
		ledgeDetection.global_rotation.y = currentCameraRotation + PI * 0.25
		cameraProbe.look_at(currentCamera.global_position, currentCamera.global_transform.basis.y)
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
	velocity = lastInvoluntarySpeed + lastVoluntarySpeed * (1.0 if is_on_floor() or len(noGravityZones) > 0 else airMovementMultiplier)
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
	facingBack = currentInputDirection.z

## Switches player animation state.
func animation_check(override: States = currentState) -> void:
	if animationPlayer.is_playing():
		for state in NOINTERRUPTSTATES:
			if animationPlayer.current_animation.begins_with(States.keys()[state]):
				currentState = state
				return
	currentState = override
	if coolStickerGrabbing: return
	lastFacingBack = lastFacingBack if facingBack == 0 else facingBack < 0
	var newAnimationName = ("Grab_" if grabArea.pickupOnHand and currentState not in NOGRABSTATES else "") + States.keys()[currentState] as String + ("_Back" if lastFacingBack else "")
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
	previousCamera = currentCamera
	CameraLerper.switch_to(camera, CAMERALERPCOOLSTICKER)
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
	return not is_on_floor() or forcedNoGravity or len(noGravityZones) > 0
#endregion

## Called when player leaves the scene DEMO SHIT
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if not GeneralVariables: return
		GeneralVariables.in_game_switch(false)
		queue_free()

## Pauses music for fanfarre
func do_fanfarre() -> void:
	MusicManager.pause(true, FANFAREWAIT.pause)
	fanfare.play()
	await fanfare.finished
	MusicManager.pause(false, FANFAREWAIT.unpause)

## Swaps active camera.
func swap_camera(newCamera: Camera3D) -> void:
	currentCamera = newCamera
	postProcessing.reparent(currentCamera)
