@tool
extends Node3D

@export var playerReference: Player

@onready var checkpoints: CheckpointsTool = %Checkpoints
@onready var currentRestartPoint: Vector3 = global_position


func _ready() -> void:
	if Engine.is_editor_hint():
		self.get_parent().set_editable_instance(self, true)
	checkpoints.checkpoint_changed.connect(change_restart_point)
	reset_player()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("reset_player"):
		reset_player()
	if event.is_action_pressed("reset_scene"):
		get_tree().reload_current_scene()

func reset_player() -> void:
	playerReference.restart_at_checkpoint(currentRestartPoint)

func change_restart_point(pos: Vector3) -> void:
	currentRestartPoint = pos
