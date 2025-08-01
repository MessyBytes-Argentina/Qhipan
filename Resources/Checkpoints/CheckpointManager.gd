extends Node3D

@export var playerReference: CharacterBody3D

@onready var checkpoints: CheckpointsTool = %Checkpoints
@onready var currentRestartPoint: Vector3 = global_position

var isOnStart = true

func _ready() -> void:
	checkpoints.checkpoint_changed.connect(change_restart_point)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("reset_player"):
		playerReference.restart( currentRestartPoint)

func change_restart_point(pos: Vector3) -> void:
	if isOnStart: isOnStart = false
	currentRestartPoint = pos
