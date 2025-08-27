@tool
extends Area3D
## The wind propelling fan object. Used inside Fan stickers too.
class_name Fan

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

## Adjust push and noGravity size and position
func set_area_size() -> void:
	if not is_node_ready(): await ready
	area.shape.size = Vector3(areaDiameter, areaHeight, areaDiameter)
	area.position.y = areaHeight / 2.0
	noGravityCollision.shape.size = Vector3(areaDiameter, areaHeight + noGravityAreaMargin, areaDiameter)
	noGravity.position.y = (areaHeight + noGravityAreaMargin) / 2.0
	target.position.y = areaHeight + (noGravityAreaMargin if hasAntigravity else 0.0)
	#TEMP
	#if $MeshInstance3D:
		#$MeshInstance3D.mesh.outer_radius = areaDiameter / 2.0
		#$MeshInstance3D.mesh.inner_radius = areaDiameter / 5.0

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.is_editor_hint(): return
	#pushForce *= PUSHBASELINE
	body_entered.connect(push)
	body_exited.connect(stop_pushing)
	set_area_size()
	target.hide()
	switch_fan(isOn)

## Turns on and off the fan
func switch_fan(mode: bool = not isOn) -> void:
	isOn = mode
	set_deferred("monitoring", isOn)
	noGravity.set_deferred("monitoring", isOn and hasAntigravity)

## On body_entered pushes the given body if pusheable
func push(body: Node3D) -> void:
	if body.has_node("InvoluntaryPushModule"): body.get_node("InvoluntaryPushModule").push(self, origin.global_position.direction_to(target.global_position), pushForce)

## On body_exited stops pushing the given body if pusheable
func stop_pushing(body: Node3D) -> void:
	if body.has_node("InvoluntaryPushModule"): body.get_node("InvoluntaryPushModule").stop_pushing(self)
