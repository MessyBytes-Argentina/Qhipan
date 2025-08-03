@tool
extends CharacterBody3D
class_name Player

const cameraRotationStep: float = deg_to_rad(90.0)
const transparencyTime: float = 0.1
const tweenTime: float = 0.25
const POPUPTIME: float = 0.5

enum States {Idle, Walk, Float}

@export_group("Character Movement")
@export_range(0, 100, .1) var maxSpeed: float = 3
@export_range(0, 100, .1) var acceleration: float = 20.0
@export_range(0, 100, .1) var decceleration: float = 20.0
@export_range(0, 100, .1) var gravity: float = 32
@export_range(0, 100, .1) var movementMaximum: float = 10:
	set(value):
		movementMaximum = value
		if Engine.is_editor_hint(): set_decal_size()
@export var disableMaximum: bool = false:
	set(value):
		disableMaximum = value
		if Engine.is_editor_hint(): set_decal_size()

@export_group("Animation Parameters")
@export_range(0, 2, .1) var cameraLerpDuration: float = 0.5
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
@onready var popUpSound: RandomPitchPlayer = $SpritePivot/Message/popUpSound

var inputDirection: Vector3 = Vector3.ZERO
var currentCameraRotation: float = 0.0
var cameraRotationTween: Tween
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
var death: bool = false
var fallSoundPlayed: bool = false
var respawnFall: bool = false
var popupTween: Tween
var stopped: bool = false
var resetButton: Button

func _ready() -> void:
	set_decal_size()
	if Engine.is_editor_hint(): return
	cameraPivot.rotation.y = rotation.y
	cameraPivot.global_position = global_position
	material = sprite.get_surface_override_material(0)
	submaterial = sprite.get_surface_override_material(0).next_pass
	postProcessing.show()
	resetButton = get_tree().get_first_node_in_group("ResetButton")

func block_inputs() -> void:
	death = true

func _input(_event: InputEvent) -> void:
	if Engine.is_editor_hint(): return
	if death: 
		inputDirection = Vector3.ZERO
		return
	inputDirection = Vector3(Input.get_action_strength("right") - Input.get_action_strength("left"), 0.0, Input.get_action_strength("backwards") - Input.get_action_strength("forwards"))
	check_movement_animation(inputDirection)
	sprite_flip_check()
	camera_rotation_check()

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	move_character(delta)
	camera_follow(delta)
	animation_check()

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
	var cameraRotation = (cameraRotationStep if Input.is_action_just_pressed("camera_left") else 0.0) - (cameraRotationStep if Input.is_action_just_pressed("camera_right") else 0.0)
	if cameraRotation != 0:
		currentCameraRotation += cameraRotation
		cameraRotationTween = create_tween()
		cameraRotationTween.tween_method(rotate_camera, spritePivot.rotation.y, currentCameraRotation, cameraLerpDuration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
		cameraRotationTween.finished.connect(rotation_finished)
		cameraRotationTween.play()
		if cameraRotation > 0:
			rotateCamLeftSound.play()
		else:
			rotateCamRightSound.play()

func rotate_camera(rotationValue: float) -> void:
	spritePivot.rotation.y = rotationValue
	cameraPivot.rotation.y = rotationValue + rotation.y

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

func move_character(delta: float) -> void:
	var moveDirection: Vector3 = get_move_direction()
	var pushForce: Vector3 = Vector3.ZERO
	for object in pushingForces:
		pushForce += pushingForces[object]
	if moved >= movementMaximum and not stopped:
		do_popup()
		resetButton.show()
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
		MusicManager.set_synchro_clip_volume("main",[1],0.0,tweenTime)
	else:
		MusicManager.set_synchro_clip_volume("main",[1],-60.0,tweenTime)
	
	moved += movedAmount
	set_decal_size()
	lastInvoluntarySpeed -= lastPushForce
	if not is_on_floor() and len(noGravityZones) == 0:
		lastInvoluntarySpeed.y -= gravity * delta
		fallSoundPlayed = false
	else:
		lastInvoluntarySpeed.y = 0
	lastPushForce = pushForce * delta
	lastInvoluntarySpeed += lastPushForce
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
	resetButton.hide()
	do_popout()
	death = true
	poofSound.play_sound()
	if transparencyTween:
		transparencyTween.kill()
	transparencyTween = create_tween()
	transparencyTween.tween_property(material, "albedo_color:a", 0.0, transparencyTime)
	transparencyTween.parallel().tween_property(submaterial, "albedo_color:a", 0.0, transparencyTime)
	transparencyTween.parallel().tween_property(shadowDecal, "modulate:a", 0.0, transparencyTime)
	transparencyTween.play()
	poof.emit_particles()
	await poof.finished
	global_position = pos
	reset_aura()
	poof.emit_particles()
	if transparencyTween:
		transparencyTween.kill()
	transparencyTween = create_tween()
	transparencyTween.tween_property(material, "albedo_color:a", 1.0, transparencyTime)
	transparencyTween.parallel().tween_property(submaterial, "albedo_color:a", 1.0, transparencyTime)
	transparencyTween.parallel().tween_property(shadowDecal, "modulate:a", 1.0, transparencyTime)
	transparencyTween.play()
	await poof.finished
	death = false
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
	popupTween = create_tween()
	popupTween.tween_property(message, "scale", Vector3.ONE, POPUPTIME * (1.0 - message.scale.x)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	popupTween.play()
	popUpSound.play_sound()

func do_popout() -> void:
	popupTween = create_tween()
	popupTween.tween_property(message, "scale", Vector3.ONE * 0.001, POPUPTIME * message.scale.x).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	popupTween.play()
