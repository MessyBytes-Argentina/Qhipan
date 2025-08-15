@tool
extends Node3D

## Reference to the Player node.
@export var playerReference: Player
## Reference to the starting checkpoint.
@export var startCheckpoint: Checkpoint
## button to move the player node position to the start checkpoint.
@export_tool_button("Take Player To Start")
var button: Callable = set_player_to_start

## Reference to the current active checkpoint.
var currentCheckpoint: Checkpoint

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.is_editor_hint(): return
	for object in get_children():
		if object is not Checkpoint or object == startCheckpoint: continue
		object.body_entered.connect(change_current_checkpoint.bind(object as Checkpoint))
	currentCheckpoint = startCheckpoint
	currentCheckpoint.activate()
	playerReference.currentCheckpointPosition = currentCheckpoint.global_position
	playerReference.restart_at_checkpoint()

## Deactivates the previous checkpoint and activates the new one.
## Reconnects on body_entered for the previous checkpoint.
## Changes the currentCheckpoint reference to the new one.
## Activates the new checkpoint and disconnects on body_entered.
## Gives the Player the new checkpoint position.
func change_current_checkpoint(_body, checkpoint: Checkpoint) -> void:
	currentCheckpoint.deactivate()
	currentCheckpoint.body_entered.connect(change_current_checkpoint.bind(currentCheckpoint as Checkpoint))
	currentCheckpoint = checkpoint
	currentCheckpoint.activate()
	currentCheckpoint.body_entered.disconnect(change_current_checkpoint)
	playerReference.currentCheckpointPosition = currentCheckpoint.global_position

## Moves the player to the starting checkpoint position
func set_player_to_start() -> void:
	playerReference.global_position = startCheckpoint.global_position
