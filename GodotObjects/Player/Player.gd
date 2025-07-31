@tool
extends CharacterBody3D

const cameraRotationStep: float = deg_to_rad(90.0)

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

func _ready() -> void:
	set_decal_size()
	if Engine.is_editor_hint(): return
	cameraPivot.rotation.y = rotation.y
	cameraPivot.global_position = global_position

func _input(_event: InputEvent) -> void:
	if Engine.is_editor_hint(): return
	inputDirection = Vector3(Input.get_action_strength("right") - Input.get_action_strength("left"), 0.0, Input.get_action_strength("backwards") - Input.get_action_strength("forwards"))
	sprite_flip_check()
	camera_rotation_check()

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	move_character(delta)
	camera_follow(delta)

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
	if moveDirection != Vector3.ZERO and (moved < movementMaximum or disableMaximum):
		lastVoluntarySpeed += (moveDirection * acceleration) * delta
		lastVoluntarySpeed = lastVoluntarySpeed.limit_length(maxSpeed)
	else:
		lastVoluntarySpeed = lastVoluntarySpeed.lerp(Vector3.ZERO, decceleration * delta)
	velocity = lastVoluntarySpeed
	move_and_slide()
	moved += (get_last_motion() * Vector3(1.0, 0.0, 1.0)).length()
	set_decal_size()
	lastInvoluntarySpeed -= lastPushForce
	if not is_on_floor() and len(noGravityZones) == 0:
		lastInvoluntarySpeed.y -= gravity * delta
	else:
		lastInvoluntarySpeed.y = 0
	lastPushForce = pushForce * delta
	lastInvoluntarySpeed += lastPushForce
	velocity = lastInvoluntarySpeed
	move_and_slide()

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
