@tool
extends CharacterBody3D
class_name Player

const CAMERAROTATIONSTEP: float = deg_to_rad(45.0)
const TRANSPARENCYTIME: float = 0.1
const STEPSOUNDTWEENTIME: float = 0.25
const POPUPTIME: float = 0.5
const RESTARTBUTTONWAIT: float = 2.0
const CAMERALERPDURATION: float = 0.25
const CAMERAZOOMOUT: Vector3 = Vector3(0, 5, 7)
const CAMERAZOOMTIME: float = 0.25
const APROXFLOORDISTANCE: float = -0.39

enum States {Idle, Walk, Float}

@export_group("Character Movement")
const maxSpeed: float = 3
const acceleration: float = 20.0
const decceleration: float = 20.0
const gravity: float = 32
@export_range(0, 100, .1) var movementMaximum: float = 10:
	set(value):
		movementMaximum = value
		if Engine.is_editor_hint(): set_decal_size()
@export var disableMaximum: bool = false:
	set(value):
		disableMaximum = value
		if Engine.is_editor_hint(): set_decal_size()

@export_group("Animation Parameters")
@export_range(0, 2, .1) var spriteFlipDuration: float = 0.5
@export_range(0, 1, .01) var cameraFollowSpeed: float = 0.1

@onready var cameraPivot: Node3D = %CameraPivot
@onready var spritePivot: Node3D = %SpritePivot
@onready var sprite: MeshInstance3D = %Sprite
@onready var lightDecal: DecalCompatibility = %LightDecal
@onready var postProcessing: MeshInstance3D = %PostProcessing
@onready var grabArea: PickupHandler = %GrabArea
@onready var animationPlayer: AnimationPlayer = %AnimationPlayer
@onready var poof: MultipleParticle3DEmitter = %Poof
@onready var shadowDecal: DecalCompatibility = %ShadowDecal
@onready var fallSound: RandomPitchPlayer = %FallSound
@onready var rotateCamLeftSound: AudioStreamPlayer = %RotateCamLeft
@onready var rotateCamRightSound: AudioStreamPlayer = %RotateCamRight
@onready var poofSound: RandomPitchPlayer = %PoofSound
@onready var message: Sprite3D = %Message
@onready var popUpSound: RandomPitchPlayer = %PopUpSound
@onready var cameraZoomPivot: Node3D = %CameraZoomPivot
@onready var playerHighlight: Sprite3D = %PlayerHighlight
@onready var cubeCutout: CutoutCube = %CubeCutout
@onready var cubeCutoutPivot: Node3D = %CubeCutoutPivot

var inputDirection: Vector3 = Vector3.ZERO
var currentCameraRotation: float = 0.0
var cameraRotationTween: Tween
var cameraZoomTween: Tween
var spriteFlipTween: Tween
var lastHorizontal: float = 1
var pushingForces: Dictionary[Node3D, Vector3] = {}
var noGravityZones: Array[Node3D] = []
var moved: float = 0.0
var lastVoluntarySpeed: Vector3 = Vector3.ZERO
var lastInvoluntarySpeed: Vector3 = Vector3.ZERO
var lastPushForce: Vector3 = Vector3.ZERO
var currentState: States = States.Idle
var facingBack: bool = false
var currentAnimation: String = "Idle"
var transparencyTween: Tween
var hasSpawned: bool = false
var material: StandardMaterial3D
var submaterial: StandardMaterial3D
var noMovement: bool = true
var fallSoundPlayed: bool = false
var respawnFall: bool = false
var popupTween: Tween
var stopped: bool = false
var resetButton: Button
var zooming: bool = false
var zoomedOut: bool = false
var inCheckpoint: bool = true
var resetPoppingOut: bool = false
var gridmap: GridMap

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
	resetButton = get_tree().get_first_node_in_group("ResetButton")
	playerHighlight.scale = Vector3.ONE * 0.001
	while not gridmap:
		gridmap = get_tree().get_first_node_in_group("Gridmap")
		await get_tree().process_frame

func _input(_event: InputEvent) -> void:
	if Engine.is_editor_hint(): return
	if noMovement or zooming: 
		inputDirection = Vector3.ZERO
		return
	inputDirection = Vector3(Input.get_action_strength("right") - Input.get_action_strength("left"), 0.0, Input.get_action_strength("backwards") - Input.get_action_strength("forwards"))
	check_movement_animation(inputDirection)
	sprite_flip_check()
	camera_rotation_check()
	camera_zoom_check()

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	move_character(delta)
	camera_follow(delta)
	animation_check()
	current_grid_check()
	grabArea.canDrop = is_on_floor()
	if not stopped:
		if resetButton: resetButton.hide()
		if not resetPoppingOut: do_popout()

func block_inputs() -> void:
	noMovement = true
	grabArea.canGrab = false

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
		spriteFlipTween.tween_method(rotate_sprite, sprite.rotation.y, 0.0 if horizontal == 1 else deg_to_rad(180), spriteFlipDuration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)
		spriteFlipTween.play()
	lastHorizontal = horizontal

func rotate_sprite(rotationValue: float) -> void:
	sprite.rotation.y = rotationValue

func camera_rotation_check() -> void:
	if cameraRotationTween: return
	var cameraRotation: float = (CAMERAROTATIONSTEP if Input.is_action_just_pressed("camera_right") else 0.0) - (CAMERAROTATIONSTEP if Input.is_action_just_pressed("camera_left") else 0.0)
	if cameraRotation == 0: return
	currentCameraRotation += cameraRotation
	cameraRotationTween = create_tween()
	cameraRotationTween.tween_method(rotate_camera, spritePivot.rotation.y, currentCameraRotation, CAMERALERPDURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	cameraRotationTween.finished.connect(rotation_finished)
	cameraRotationTween.play()
	if cameraRotation > 0:
		rotateCamLeftSound.play()
	else:
		rotateCamRightSound.play()

func rotate_camera(rotationValue: float) -> void:
	spritePivot.rotation.y = rotationValue
	cameraPivot.rotation.y = rotationValue + rotation.y

func camera_zoom_check() -> void:
	if zooming: return
	var doZoom: bool = Input.is_action_just_pressed("zoom") or (zoomedOut and inputDirection.length() > 0)
	if not doZoom: return
	cubeCutout.zoomedOut = not zoomedOut
	zooming = true
	noMovement = true
	grabArea.canGrab = false
	cameraZoomTween = create_tween()
	cameraZoomTween.tween_property(cameraZoomPivot, "position", CAMERAZOOMOUT if not zoomedOut else Vector3.ZERO, CAMERAZOOMTIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	cameraZoomTween.parallel().tween_property(playerHighlight, "scale", (Vector3.ONE * 0.001) if zoomedOut else Vector3.ONE, CAMERAZOOMTIME).set_trans(Tween.TRANS_SINE)
	cameraZoomTween.finished.connect(rotation_finished)
	cameraZoomTween.play()
	await cameraZoomTween.finished
	zooming = false
	noMovement = false
	grabArea.canGrab = true
	zoomedOut = not zoomedOut
	grabArea.zoomedOut = zoomedOut

func rotation_finished() -> void:
	if fmod(currentCameraRotation, deg_to_rad(360.0)) == 0.0: 
		currentCameraRotation = 0.0
		spritePivot.rotation.y = 0.0
		cameraPivot.rotation.y = rotation.y
	if cameraRotationTween: 
		cameraRotationTween.kill()
		cameraRotationTween = null

func camera_follow(_delta: float) -> void:
	cameraPivot.global_position = lerp(cameraPivot.global_position, global_position, cameraFollowSpeed)

func current_grid_check() -> void:
	if not gridmap: return
	var currentGridPosition: Vector3 = Vector3(gridmap.local_to_map(global_position - gridmap.global_position)) * gridmap.cell_size + gridmap.global_position + gridmap.cell_size / 2.0
	var pushOnPerpendicularCamera: Vector3 = (Vector3(-0.5, 0.0, -0.5).rotated(Vector3.UP, currentCameraRotation).normalized() / 2.0) if fmod(currentCameraRotation, PI / 2) != 0 else (Vector3.FORWARD * sqrt(2.0)).rotated(Vector3.UP, currentCameraRotation)
	cubeCutoutPivot.global_position = currentGridPosition + pushOnPerpendicularCamera
	cubeCutoutPivot.rotation.y = cameraPivot.rotation.y

func move_character(delta: float) -> void:
	var moveDirection: Vector3 = get_move_direction()
	var pushForce: Vector3 = Vector3.ZERO
	for object in pushingForces:
		pushForce += pushingForces[object]
	if moved >= movementMaximum and not stopped:
		do_popup()
		if resetButton: get_tree().create_timer(RESTARTBUTTONWAIT).timeout.connect(show_restart)
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
	if not is_on_floor() and len(noGravityZones) == 0 and not respawnFall:
		lastInvoluntarySpeed.y -= gravity * delta
		fallSoundPlayed = false
	else:
		lastInvoluntarySpeed.y = 0
	lastPushForce = pushForce * delta
	lastInvoluntarySpeed = (lastInvoluntarySpeed + lastPushForce) if not respawnFall else Vector3.ZERO
	if (pushForce.length() > 0 or len(noGravityZones) > 0) and currentState != States.Float: currentState = States.Float
	if pushForce.length() == 0 and currentState == States.Float and len(noGravityZones) == 0:
		currentState = States.Idle
		animation_check()
	velocity = lastInvoluntarySpeed
	move_and_slide()
	if is_on_floor() and not fallSoundPlayed and not respawnFall:
		fallSound.play_sound()
	fallSoundPlayed = true

func get_move_direction() -> Vector3:
	var moveDirection: Vector3 = inputDirection
	moveDirection = moveDirection.rotated(Vector3.UP, rotation.y)
	moveDirection = moveDirection.rotated(Vector3.UP, currentCameraRotation)
	return moveDirection

func push(node: Node3D, direction: Vector3, force: float) -> void:
	pushingForces[node] = direction * force

func stop_pushing(node: Node3D) -> void:
	pushingForces.erase(node)

func enter_no_gravity(node: Node3D) -> void:
	if not noGravityZones.has(node): noGravityZones.append(node)
	
func exit_no_gravity(node: Node3D) -> void:
	noGravityZones.erase(node)

func set_decal_size() -> void:
	if disableMaximum:
		if lightDecal: lightDecal.hide()
		return
	lightDecal.size.x = (movementMaximum - moved) * 2.0
	lightDecal.size.z = lightDecal.size.x

func enable_checkpoint_sound() -> void:
	get_tree().call_group("Checkpoints","enable_sounds")

func restart_at_checkpoint(pos: Vector3) -> void:
	#Al final parece que no se tienen que droppear
	#grabArea.drop(true)
	respawnFall = true
	get_tree().create_timer(1.0).timeout.connect(set.bind("respawnFall", false))
	get_tree().create_timer(1.0).timeout.connect(enable_checkpoint_sound)
	if not hasSpawned:
		global_position = pos
		reset_aura()
		hasSpawned = true
		return
	if resetButton: resetButton.hide()
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
	poof.emit_particles()
	await poof.finished
	global_position = pos
	reset_aura()
	poof.emit_particles()
	if transparencyTween:
		transparencyTween.kill()
	transparencyTween = create_tween()
	transparencyTween.tween_property(material, "albedo_color:a", 1.0, TRANSPARENCYTIME)
	transparencyTween.parallel().tween_property(submaterial, "albedo_color:a", 1.0, TRANSPARENCYTIME)
	transparencyTween.parallel().tween_property(shadowDecal, "modulate:a", 1.0, TRANSPARENCYTIME)
	transparencyTween.play()
	await poof.finished
	noMovement = false
	grabArea.canGrab = true
	stopped = false

func reset_aura() -> void:
	moved = 0
	set_decal_size()

func animation_check() -> void:
	var newAnimationName = ("Grab_" if grabArea.pickupOnHand else "") + States.keys()[currentState] as String + ("_Back" if facingBack else "")
	if newAnimationName != currentAnimation:
		animationPlayer.play(newAnimationName)
		currentAnimation = newAnimationName

func check_movement_animation(currentInputDirection: Vector3) -> void:
	if currentState != States.Float: currentState = States.Walk if currentInputDirection.length() > 0 else States.Idle
	if currentInputDirection.z == 0 and currentState != States.Idle: return
	facingBack = currentInputDirection.z < 0

func do_popup() -> void:
	if popupTween:
		popupTween.kill()
		resetPoppingOut = false
	popupTween = create_tween()
	popupTween.tween_property(message, "scale", Vector3.ONE, POPUPTIME * (1.0 - message.scale.x)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	popupTween.play()
	popUpSound.play_sound()

func do_popout() -> void:
	if popupTween:
		popupTween.kill()
	resetPoppingOut = true
	popupTween = create_tween()
	popupTween.tween_property(message, "scale", Vector3.ONE * 0.001, POPUPTIME * message.scale.x).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	popupTween.play()
	popupTween.finished.connect(set.bind("resetPoppingOut", false))

func show_restart() -> void:
	if stopped: resetButton.show()

func checkpoint_entered() -> void:
	inCheckpoint = true
	moved = 0

func checkpoint_exited() -> void:
	inCheckpoint = false
