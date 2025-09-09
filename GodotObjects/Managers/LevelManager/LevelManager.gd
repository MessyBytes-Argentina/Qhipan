extends Node

## Path to the credits scene
const creditsScene: String = "uid://b8wvtujbncu6r"

## Array with the list of paths to the levels scenes
var levelList: Array[String]
## Reference to the SceneManager (assigned at the ready function)
var sceneManager: StoryWriterSceneManager
## Current level id for the list progress
var currentLvlId: int = 0
## Restarted flag
var restarted: bool = false

## WIN CODE
#func _process(_delta: float) -> void:
	#if Input.is_action_pressed("camera_left") and Input.is_action_pressed("camera_right"):
		#next_level()

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Awaiting for the SceneManager to load
	while not sceneManager:
		await get_tree().process_frame
		sceneManager = get_tree().get_first_node_in_group("SceneManager")

## Reloads the current level when called
func do_restart() -> void:
	if not sceneManager:
		get_tree().reload_current_scene()
		return
	restarted = true
	sceneManager.switch_scene()
	await sceneManager.finished
	await get_tree().create_timer(1.0).timeout
	restarted = false

## Changes the current scene to the next level on the list.
## if there are no more levels it changes to the credits scene
func next_level() -> void:
	currentLvlId += 1
	if currentLvlId < len(levelList):
		_load_new_scene(levelList[currentLvlId])
	else:
		go_to_credits()

## returns level list size.
func get_list_size() -> int:
	return len(levelList)

## Changes the current scene to the given number of the level list.
func change_to_id(id: int) -> void:
	if id >= 0 and id < len(levelList):
		currentLvlId = id
		_load_new_scene(levelList[id])

## Sets the level list to the given list, then loads the first item on the list.
func set_list(list: Array[String]) -> void:
	levelList = list
	currentLvlId = 0
	change_to_id(0)

## Clears the level list and changes the scene to the given scene path.
func change_level_to_path(lvlPath: String) -> void:
	levelList.clear()
	levelList.append(lvlPath)
	currentLvlId = 0
	_load_new_scene(levelList[currentLvlId])

## Adds given path to the list of levels.
func add_level(lvlPath: String) -> void:
	levelList.append(load(lvlPath))

## Changes the scene to the given scene (do not call from outside LevelManager).
func _load_new_scene(scene: String) -> void:
	sceneManager.load_and_switch(scene)

## It do what it says.
func go_to_credits() -> void:
	_load_new_scene(creditsScene)
