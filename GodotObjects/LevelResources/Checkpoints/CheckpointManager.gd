@tool
extends Node3D

@export var playerReference: Player
@export var startCheckpoint: Checkpoint
@export_tool_button("Take Player To Start")
var button: Callable = set_player_to_start

var currentCheckpoint: Checkpoint
var inputsBlocked: bool = false
var checkpointResetAmount: int = 0

func _ready() -> void:
	if Engine.is_editor_hint(): return
	for object in get_children():
		if object is not Checkpoint or object == startCheckpoint: continue
		object.body_entered.connect(change_current_checkpoint.bind(object as Checkpoint))
	currentCheckpoint = startCheckpoint
	currentCheckpoint.activate()
	reset_player()

func block_inputs() -> void:
	inputsBlocked = true

func _input(_event: InputEvent) -> void:
	if inputsBlocked: return
	if Input.is_action_just_pressed("reset_player") and not playerReference.noMovement:
		checkpointResetAmount += 1
		reset_player()

func reset_player() -> void:
	playerReference.restart_at_checkpoint(currentCheckpoint.global_position)

func change_current_checkpoint(_body, checkpoint: Checkpoint) -> void:
	currentCheckpoint.deactivate()
	currentCheckpoint.body_entered.connect(change_current_checkpoint.bind(currentCheckpoint as Checkpoint))
	currentCheckpoint = checkpoint
	currentCheckpoint.activate()
	currentCheckpoint.body_entered.disconnect(change_current_checkpoint)

func set_player_to_start() -> void:
	playerReference.global_position = startCheckpoint.global_position
