@tool
extends Node3D
class_name CheckpointsTool

@export var checkpointScene: PackedScene 
@export_tool_button("Add Checkpoint") var addFunc = add_checkpoint

var checkpointList: Array[Node]
var currentCheckpoint: Area3D

signal checkpoint_changed

func _ready() -> void:
	if not Engine.is_editor_hint() :
		checkpointList = get_children()
		for object: Area3D in checkpointList:
			object.body_entered.connect(change_current_checkpoint.bind(object))

func change_current_checkpoint(checkpoint: Area3D) -> void:
	currentCheckpoint = checkpoint
	currentCheckpoint.body_entered.disconnect(change_current_checkpoint)
	emit_signal("checkpoint_changed", currentCheckpoint.global_position)

func add_checkpoint():
	var newCheckpoint = checkpointScene.instantiate()
	add_child(newCheckpoint)
	newCheckpoint.name = "Checkpoint"
	newCheckpoint.owner = get_tree().edited_scene_root
