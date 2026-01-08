@tool
extends Area3D

## Class for [Area3d] to hide or show nodes.
class_name ObjectHider

## Objects to hide / show and their status once this area is entered. Use true for visible, false for invisible.
@export var objects: Dictionary[Node3D, bool] = {}
## Paired object hider. If this is turned on the other is considered off. Useful for save states.
@export var pairedHider: ObjectHider
## Group to hide storage only variables because export storage doesn't seem to do the thing.
@export_group("Root Reference")
## Parent node reference for placement.
@export var sceneParent: Node
## Default mode.
@export var isActive: bool = false

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.is_editor_hint():
		var testSceneParent = get_tree().edited_scene_root
		if testSceneParent.has_node("Player"): return
		sceneParent = testSceneParent
		return
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	set_collision_mask_value(2, not isActive)
	body_entered.connect(_on_body_entered)

## Executed on every frame.
func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): 
		var testSceneParent = get_tree().edited_scene_root
		if testSceneParent == sceneParent: return
		if testSceneParent.has_node("Player"): return
		sceneParent = testSceneParent

## On player entering node
func _on_body_entered(body: Node) -> void:
	if body is not Player: return
	for object in objects: object.visible = objects[object]
	GeneralVariables.saveManager.store_change(self, sceneParent)
	set_collision_mask_value(2, false)
	if pairedHider:
		pairedHider.set_collision_mask_value(2, true)
		GeneralVariables.saveManager.store_change(pairedHider, pairedHider.sceneParent)

func restore_save(mode: bool) -> void:
	set_collision_mask_value(2, not mode)
	if mode:
		for object in objects: object.visible = objects[object]
