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
	reset_player()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("reset_player"):
		reset_player()
	if event.is_action_pressed("reset_scene"):
		get_tree().reload_current_scene()

func reset_player() -> void:
	playerReference.restart_at_checkpoint(currentCheckpoint.global_position)

func change_current_checkpoint(_body, checkpoint: Checkpoint) -> void:
	currentCheckpoint.body_entered.connect(change_current_checkpoint.bind(currentCheckpoint as Checkpoint))
	currentCheckpoint = checkpoint
	currentCheckpoint.body_entered.disconnect(change_current_checkpoint)

func set_player_to_start() -> void:
	playerReference.global_position = startCheckpoint.global_position
