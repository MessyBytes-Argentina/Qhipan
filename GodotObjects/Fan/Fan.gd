@tool
extends Area3D

const PUSHBASELINE: float = 5

@export var isOn: bool = true
@export_range(0.0, 100, 0.01) var pushForce: float = 1.0
@export_range(0.0, 100, 0.01) var areaHeight: float = 1.0:
	set(value):
		areaHeight = value
		if not Engine.is_editor_hint(): return
		set_area_size()
@export_range(0.0, 100, 0.01) var areaDiameter: float = 0.5:
	set(value):
		areaDiameter = value
		if not Engine.is_editor_hint(): return
		set_area_size()
@export var hasAntigravity: bool = true
@export_range(-1.0, 1, 0.01) var noGravityAreaMargin: float = 0.1:
	set(value):
		noGravityAreaMargin = value
		if not Engine.is_editor_hint(): return
		set_area_size()

@onready var target: Marker3D = %Target
@onready var origin: Marker3D = %Origin
@onready var area: CollisionShape3D = %Area
@onready var noGravity: NoGravityZone = %NoGravity
@onready var noGravityCollision: CollisionShape3D = %NoGravityCollision

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

func _ready() -> void:
	if Engine.is_editor_hint(): return
	pushForce *= PUSHBASELINE
	body_entered.connect(push)
	body_exited.connect(stop_pushing)
	set_area_size()
	target.hide()
	switch_fan(isOn)

func switch_fan(mode: bool = not isOn) -> void:
	isOn = mode
	set_deferred("monitoring", isOn)
	noGravity.set_deferred("monitoring", isOn and hasAntigravity)

func push(body: Node3D) -> void:
	if body.has_method("push"): body.push(self, origin.global_position.direction_to(target.global_position), pushForce)

func stop_pushing(body: Node3D) -> void:
	if body.has_method("stop_pushing"): body.stop_pushing(self)
