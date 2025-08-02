extends Node

@export var levelList: Array[PackedScene]

@onready var creditsScene: PackedScene = load("res://UI/Credits.tscn")
var currentLvlId: int = 0

func next_level() -> void:
	currentLvlId += 1
	if currentLvlId < len(levelList):
		load_new_scene.call_deferred(levelList[currentLvlId])
	else:
		go_to_credits()

func get_list_size() -> int:
	return len(levelList)

func change_to_id(id: int) -> void:
	if id >= 0 and id < len(levelList):
		currentLvlId = id
		load_new_scene.call_deferred(levelList[id])

func set_list(list: Array[PackedScene], loadFirstLevel: bool = true) -> void:
	levelList = list
	currentLvlId = 0
	if loadFirstLevel:
		change_to_id(0)

func change_level(lvlName: String) -> void:
	levelList.clear()
	levelList.append(load(lvlName))
	currentLvlId = 0
	load_new_scene.call_deferred(levelList[currentLvlId])

func add_level(lvlName: String) -> void:
	levelList.append(load(lvlName))

func load_new_scene(scene: PackedScene) -> void:
	get_tree().change_scene_to_packed(scene)

func go_to_credits() -> void:
	get_tree().change_scene_to_packed.call_deferred(creditsScene)
