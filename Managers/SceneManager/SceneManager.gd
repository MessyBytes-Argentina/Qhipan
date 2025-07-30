@icon("./Director.svg")
extends Node

## Load scenes into Scene container.
## do_transition(scenepath) to do the load process.
class_name SceneManagerObject

## The scene to move to after the starting animation.
@export_file("*.tscn") var startScene: String

## A reference to the animation player.
@onready var animationPlayer: AnimationPlayer = %TransitionAnimator
## A reference to the screenshot holder.
@onready var sceneScreenshot: TextureRect = %SceneScreenshot
## A reference to the scene container.
@onready var sceneContainer: Node = %SceneContainer
## A reference to the loader scene.
@onready var loaderScene: Control = %LoaderScene
## A reference to the loader scene layer.
@onready var loaderLayer = %LoaderLayer

## Path of the scene to go to.
var toGoScenePath: String
## Scene to go to.
var toGoScene: PackedScene
## Loaded scene to go to.
var newScene: Node

## This signal notifies when the scene loaded.
signal scene_loaded

## Scene loader thread
var thread: Thread = Thread.new()

## Transitions to the provided scene.
func do_transition(toGoPath: String) -> void:
	toGoScenePath = toGoPath
	get_tree().paused = true
	# Takes a screenshot of the viewport
	var viewportImage = get_viewport().get_texture().get_image()
	var screenshot = ImageTexture.new()
	screenshot = ImageTexture.create_from_image(viewportImage)
	sceneScreenshot.texture = screenshot
	sceneScreenshot.visible = true
	sceneContainer.get_child(0).queue_free()
	animationPlayer.play("RESET")
	## Transition to loader
	animationPlayer.play("ToLoader")

## Finishes the transition, loads the scene a hides the loader.
func end_transition() -> void:
	sceneScreenshot.texture = null
	move_child(sceneContainer, 0)
	await get_tree().create_timer(0.1).timeout
	if toGoScenePath:
		thread.start(_background_load.bind(toGoScenePath))

## Loads a scene on a second thread.
func _background_load(scenePath: String) -> PackedScene:
	call_deferred("_load_done")
	return load(scenePath)

## Finish the load sequence.
func _load_done() -> void:
	toGoScene = thread.wait_to_finish()
	newScene = toGoScene.instantiate()
	animationPlayer.play("RESET")
	newScene.ready.connect(unload)
	sceneContainer.add_child(newScene)

## Disconnects and connects stuff when the scene finishes loading.
func unload() -> void:
	newScene.ready.disconnect(unload)
	ButtonSoundManager.install_sounds()
	animationPlayer.play("FromLoader")

## To trigger upon finishing transition animations.
func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "ToLoader":
		end_transition()
	elif anim_name == "FromLoader":
		loaderScene.visible = false
		move_child(loaderLayer, 0)
		animationPlayer.play("RESET")
		scene_loaded.emit()
		get_tree().paused = false

## Moves to the start scene.
func go_to_start_scene():
	do_transition(startScene)
