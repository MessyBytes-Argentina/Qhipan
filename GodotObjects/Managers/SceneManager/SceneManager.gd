extends Control

## This Scene handles transitioning fro main scenes.
class_name StoryWriterSceneManager

## Signals the end of a scene switch.
signal finished()

## The wait time after a scene is loaded in.
const loadExtraTime: float = 1.0
## The animation time.
const loadAnimationTime: float = 1.0
const loadSameScene: float = 0.5
## The wait time after the animation finished.
const loadAnimationExtraTime: float = 0.0
## The time to spread back the hexes on loading time extended.
const loadAnimationWaitTime: float = 0.5

## Reference to the shader ColorRect.
@onready var shaderColorRect: ColorRect = %ShaderColorRect
## Reference to the loader subviewport.
@onready var loaderSubViewport: SubViewport = %LoaderSubViewport
## Reference to the main subviewport.
@onready var mainSubViewport: Control = %MainSubViewportContainer
@onready var blockScreen: CanvasLayer = $BlockScreen

## A Dictionary of scenes loaded.
var loadedScenes: Dictionary[String, Dictionary] = {}
## The currently requested main scene.
var requested: String = ""
## Toggle used for transitions.
var transitioning: bool = false
## The actual viewport size.
var currentViewportSize: Vector2
## Transition tween.
var transitionTween: Tween
## Doing transition setup.
var inSetup: bool = false

var currentScene: String
var reloaded: bool = false
var requestedSwitch: bool = false

## Starts loading a given scene.
func load_scene(sceneName: String, path: String) -> void:
	if loadedScenes.has(sceneName):
		return
	loadedScenes[sceneName] = {
		"path": path,
		"scene": null
	}
	ResourceLoader.load_threaded_request(path, "PackedScene", true)

## Removes a scene from memory.
func erase_scene(sceneName: String) -> void:
	loadedScenes.erase(sceneName)

## Load and switch
func load_and_switch(path: String, sceneName: String = "") -> void:
	if sceneName == "": sceneName = path.get_file().get_basename()
	load_scene(sceneName, path)
	requestedSwitch = true
	switch_scene(sceneName)
	currentScene = sceneName

## Executed every frame.
func _process(_delta: float) -> void:
	if not inSetup:
		for key in loadedScenes:
			if loadedScenes[key].scene == null:
				var progress: Array = []
				match ResourceLoader.load_threaded_get_status(loadedScenes[key].path, progress):
					ResourceLoader.THREAD_LOAD_LOADED:
						loadedScenes[key].scene = ResourceLoader.load_threaded_get(loadedScenes[key].path)
						if requestedSwitch: finish_scene_switch()
					ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
						push_error("An error occurred while loading scene '" + key + "' with path '" + loadedScenes[key].path + "'.")
	if currentViewportSize != get_viewport_rect().size:
		currentViewportSize = get_viewport_rect().size
		loaderSubViewport.size = currentViewportSize
		mainSubViewport.size = currentViewportSize

## Switches the main scene to the given one.
func switch_scene(sceneName: String = currentScene) -> void:
	blockScreen.show()
	reloaded = sceneName == currentScene
	await get_tree().process_frame
	inSetup = true
	get_tree().paused = true
	requested = sceneName
	transitionTween = create_tween()
	transitionTween.tween_method(custom_set_shader_parameter.bind("progress"), 0.0, 1.0, loadAnimationTime if not reloaded else loadSameScene).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	transitionTween.tween_method(custom_set_shader_parameter.bind("transparency") ,0.0 , 1.0, loadAnimationExtraTime)
	transitionTween.play()
	await transitionTween.finished
	await get_tree().process_frame
	mainSubViewport.get_child(0).queue_free()
	if not loadedScenes.has(sceneName):
		push_error("Requested scene '" + sceneName + "' was never queued to load.")
		return
	if loadedScenes[sceneName].scene != null:
		finish_scene_switch()
	else:
		var progress: Array = []
		match ResourceLoader.load_threaded_get_status(loadedScenes[requested].path, progress):
			ResourceLoader.THREAD_LOAD_LOADED:
				loadedScenes[requested].scene = ResourceLoader.load_threaded_get(loadedScenes[requested].path)
				finish_scene_switch()
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				transitioning = true
				transitionTween = create_tween()
				transitionTween.tween_method(custom_set_shader_parameter.bind("progress"), 1.0, 0.5, loadAnimationWaitTime).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
				transitionTween.tween_interval(loadAnimationExtraTime*10)
				transitionTween.play()
				await transitionTween.finished
	inSetup = false

## Finishes scene switching.
func finish_scene_switch() -> void:
	if transitionTween:
		if transitionTween.is_running():
			await transitionTween.finished
	mainSubViewport.add_child(loadedScenes[requested].scene.instantiate())
	await get_tree().process_frame
	transitionTween = create_tween()
	if transitioning:
		transitionTween.tween_method(custom_set_shader_parameter.bind("progress"), 0.5, 1.0, loadAnimationWaitTime).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)
		transitioning = false
	transitionTween.tween_method(custom_set_shader_parameter.bind("transparency"), 1.0 , 0.0, loadAnimationExtraTime)
	transitionTween.tween_method(custom_set_shader_parameter.bind("progress"), 1.0, 0.0, loadAnimationTime if not reloaded else loadSameScene).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	reloaded = false
	transitionTween.play()
	transitionTween.finished.connect(fin_transition)
	get_tree().paused = false
	finished.emit()

func fin_transition() -> void:
	blockScreen.hide()
	var player: Player = get_tree().get_first_node_in_group("Player")
	if player: player.noMovement = false

## Shader set parameter function
func custom_set_shader_parameter(value: Variant, parameter: String) -> void:
	shaderColorRect.material.set_shader_parameter(parameter, value)

## Returns a given Scene.
func get_scene(sceneName: String) -> PackedScene:
	if loadedScenes[sceneName].scene == null:
		while ResourceLoader.load_threaded_get_status(loadedScenes[sceneName].path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await get_tree().process_frame
		if ResourceLoader.load_threaded_get_status(loadedScenes[sceneName].path) in [ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE]:
			push_error("An error occurred while loading scene '" + sceneName + "' with path '" + loadedScenes[sceneName].path + "'.")
			return null
	return loadedScenes[sceneName].scene
