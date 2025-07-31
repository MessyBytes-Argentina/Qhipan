@tool
extends Area3D

const PUSHBASELINE: float = 5

@export_range(0.0, 10, 0.1) var pushForce: float = 1.0
@export_range(-100.0, 100, 0.1) var areaHeight: float = 1.0:
	set(value):
		areaHeight = value
		if not Engine.is_editor_hint(): return
		set_area_height()
@export var hasAntigravity: bool = true
@export_range(-1.0, 1, 0.1) var noGravityAreaMargin: float = 0.1:
	set(value):
		noGravityAreaMargin = value
		if not Engine.is_editor_hint(): return
		set_area_height()

@onready var target: Marker3D = %Target
@onready var origin: Marker3D = %Origin
@onready var area: CollisionShape3D = %Area
@onready var noGravity: NoGravityZone = %NoGravity
@onready var noGravityCollision: CollisionShape3D = %NoGravityCollision

func set_area_height() -> void:
	area.shape.height = areaHeight
	area.position.y = areaHeight / 2.0
	noGravityCollision.shape.radius = area.shape.radius
	noGravityCollision.shape.height = areaHeight + noGravityAreaMargin
	noGravity.position.y = (areaHeight + noGravityAreaMargin) / 2.0
	target.position.y = areaHeight + (noGravityAreaMargin if hasAntigravity else 0.0)
	noGravity.set_deferred("monitorable", hasAntigravity)
	noGravity.set_deferred("monitoring", hasAntigravity)

func _ready() -> void:
	if Engine.is_editor_hint(): return
	pushForce *= PUSHBASELINE
	body_entered.connect(push)
	body_exited.connect(stop_pushing)
	set_area_height()
	target.hide()

func push(body: Node3D) -> void:
	if body.has_method("push"): body.push(self, origin.global_position.direction_to(target.global_position), pushForce)

func stop_pushing(body: Node3D) -> void:
	if body.has_method("stop_pushing"): body.stop_pushing(self)
