@tool
extends Area3D
## The wind propelling fan object. Used inside Fan stickers too.
class_name Fan

const STICKERFLAG: int = 2

## Fan activation flag
@export var isOn: bool = false
## Antigravity on/off flag
@export var hasAntigravity: bool = true
## Pushing area lenght
@export_range(0.0, 100, 0.01) var areaHeight: float = 3.0:
	set(value):
		areaHeight = value
		if not Engine.is_editor_hint(): return
		set_area_size()

## Amount of force the player is pushed by
const pushForce: float = 250.0
## Pushing area diameter
const areaDiameter: float = 0.8
## Extra lenght of no gravity
const noGravityAreaMargin: float = 0.15

## Target marker for direction
@onready var target: Marker3D = %Target
## Origin marker for direction
@onready var origin: Marker3D = %Origin
## Pushing area collision shape reference
@onready var area: CollisionShape3D = %Area
## NoGravity zone reference
@onready var noGravity: NoGravityZone = %NoGravity
## NoGravity area collision shape reference
@onready var noGravityCollision: CollisionShape3D = %NoGravityCollision
## Raycast to detect wind-blocking structures.
@onready var blockingRaycast: RayCast3D = %BlockingRaycast
## Fan particle emmiter.
@onready var fanParticles: GPUParticles3D = %FanParticles

## Last raycast collision length.
var lastRayCollision: float = 0.0

## Adjust push and noGravity size and position
func set_area_size(overridenSize: float = areaHeight) -> void:
	if not is_node_ready(): await ready
	area.shape.size = Vector3(areaDiameter, overridenSize, areaDiameter)
	area.position.y = overridenSize / 2.0
	noGravityCollision.shape.size = Vector3(areaDiameter, overridenSize + (noGravityAreaMargin if overridenSize == areaHeight else 0.0), areaDiameter)
	noGravity.position.y = (overridenSize + (noGravityAreaMargin if overridenSize == areaHeight else 0.0)) / 2.0
	target.position.y = overridenSize + ((noGravityAreaMargin if overridenSize == areaHeight else 0.0) if hasAntigravity else 0.0)
	if fanParticles: 
		fanParticles.interp_to_end = (1.0 - overridenSize / areaHeight) / 6.0
	if blockingRaycast.target_position.y == 0.0:
		blockingRaycast.target_position.y = overridenSize + noGravityAreaMargin

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.is_editor_hint(): return
	area.shape = area.shape.duplicate()
	noGravityCollision.shape = noGravityCollision.shape.duplicate()
	body_entered.connect(push)
	body_exited.connect(stop_pushing)
	set_area_size()
	target.hide()
	switch_fan(isOn)

## Called during the physics processing step of the main loop.
func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint(): return
	check_obstacles()

## Checks for wind blocking elements
func check_obstacles() -> void:
	if blockingRaycast.target_position.y == 0: return
	if not blockingRaycast.is_colliding():
		if lastRayCollision != 0.0:
			set_area_size()
			lastRayCollision = 0.0
		return
	var currentRayCollision: float = roundf(global_position.distance_to(blockingRaycast.get_collision_point()))
	if lastRayCollision != currentRayCollision:
		lastRayCollision = currentRayCollision
		set_area_size(lastRayCollision)

## Turns on and off the fan
func switch_fan(mode: bool = not isOn) -> void:
	isOn = mode
	set_deferred("monitoring", isOn)
	if fanParticles: fanParticles.emitting = mode
	noGravity.set_deferred("monitoring", isOn and hasAntigravity)

## On body_entered pushes the given body if pusheable
func push(body: Node3D) -> void:
	if body.has_node("InvoluntaryPushModule"): body.get_node("InvoluntaryPushModule").push(self, origin.global_position.direction_to(target.global_position), pushForce)

## On body_exited stops pushing the given body if pusheable
func stop_pushing(body: Node3D) -> void:
	if body.has_node("InvoluntaryPushModule"): body.get_node("InvoluntaryPushModule").stop_pushing(self)
