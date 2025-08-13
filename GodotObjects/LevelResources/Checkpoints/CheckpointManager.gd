@tool
extends Node3D

@export var playerReference: Player
@export var startCheckpoint: Checkpoint
@export_tool_button("Take Player To Start")
var button: Callable = set_player_to_start

var currentCheckpoint: Checkpoint

func _ready() -> void:
	if Engine.is_editor_hint(): return
	for object in get_children():
		if object is not Checkpoint or object == startCheckpoint: continue
		object.body_entered.connect(change_current_checkpoint.bind(object as Checkpoint))
	currentCheckpoint = startCheckpoint
	currentCheckpoint.activate()
	playerReference.currentCheckpointPosition = currentCheckpoint.global_position
	playerReference.restart_at_checkpoint()

func change_current_checkpoint(_body, checkpoint: Checkpoint) -> void:
	currentCheckpoint.deactivate()
	currentCheckpoint.body_entered.connect(change_current_checkpoint.bind(currentCheckpoint as Checkpoint))
	currentCheckpoint = checkpoint
	currentCheckpoint.activate()
	currentCheckpoint.body_entered.disconnect(change_current_checkpoint)
	playerReference.currentCheckpointPosition = currentCheckpoint.global_position

func set_player_to_start() -> void:
	playerReference.global_position = startCheckpoint.global_position
