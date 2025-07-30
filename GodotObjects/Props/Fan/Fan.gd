extends Area3D

@export_range(1, 100, 0.1) var pushForce: float = 30

@onready var target: Marker3D = $Target
@onready var origin: Marker3D = $Origin

func _ready() -> void:
	body_entered.connect(push)
	body_exited.connect(stop_pushing)

func push(body) -> void:
	body.push(origin.position.direction_to(target.position), pushForce)

func stop_pushing(body) -> void:
	body.stop_pushing()
