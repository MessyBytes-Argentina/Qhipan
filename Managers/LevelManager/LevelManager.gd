extends Node

var levelList: Array[String]
var creditsScene: String = "res://UI/Restart.tscn"
var sceneManager:StoryWriterSceneManager
var currentLvlId: int = 0

func _ready() -> void:
	while not sceneManager:
		await get_tree().process_frame
		sceneManager = get_tree().get_first_node_in_group("SceneManager")

func next_level() -> void:
	currentLvlId += 1
	if currentLvlId < len(levelList):
		load_new_scene(levelList[currentLvlId])
	else:
		go_to_credits()

func get_list_size() -> int:
	return len(levelList)

func change_to_id(id: int) -> void:
	if id >= 0 and id < len(levelList):
		currentLvlId = id
		load_new_scene(levelList[id])

func set_list(list: Array[String], loadFirstLevel: bool = true) -> void:
	levelList = list
	currentLvlId = 0
	if loadFirstLevel:
		change_to_id(0)

func change_level(lvlPath: String) -> void:
	levelList.clear()
	levelList.append(lvlPath)
	currentLvlId = 0
	load_new_scene(levelList[currentLvlId])

func add_level(lvlPath: String) -> void:
	levelList.append(load(lvlPath))

func load_new_scene(scene: String) -> void:
	sceneManager.load_and_switch(scene)

func go_to_credits() -> void:
	load_new_scene(creditsScene)
