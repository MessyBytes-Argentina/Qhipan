@tool
extends Node3D

## Class for hiding or showing nodes.
class_name ObjectOccluder

## Visual data for the colliders.
const DEBUGCOLORS: Dictionary[String, Color] = {"ONShape": Color.DEEP_SKY_BLUE * Color(Color.WHITE, 0.5), "OFFShape": Color.DEEP_PINK * Color(Color.WHITE, 0.5)}
## Forced mode enum
enum ForceModes {OFF, TRUE, FALSE}

## Objects to show.
@export var showObjects: Array[Node3D] = []
## Objects to hide.
@export var hideObjects: Array[Node3D] = []
## Buton to test for the current positioning of scenes.
@export_tool_button("Add ON Shape", "BoxShape3D") var addLoadShape: Callable = add_shape.bind("ONShape") 
## Buton to test for the current positioning of scenes.
@export_tool_button("Add OFF Shape", "BoxMesh") var addUnloadShape: Callable = add_shape.bind("OFFShape")
## Group to hide storage only variables because export storage doesn't seem to do the thing.
@export_group("Root Reference")
## Parent node reference for placement.
@export var sceneParent: Node

## Reference to the Area3Ds used to turn on this object.
var onAreas: Array[Area3D]
## Reference to the Area3Ds used to turn off this object.
var offAreas: Array[Area3D]
## Reference to the CollisionShape3Ds used to turn on this object.
var onShapes: Array[CollisionShape3D] = []
## Reference to the CollisionShape3Ds used to turn off this object.
var offShapes: Array[CollisionShape3D] = []
## Current mode.
var isActive: bool = false
## Force flag.
var forceMode: ForceModes = ForceModes.OFF

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var children: Array[Node] = get_children()
	children.map(func(a: Node): 
		if a is not CollisionShape3D: return
		if not a.shape: a.queue_free(); return
		if a.has_meta("ONShape"): onShapes.append(a) 
		elif a.has_meta("OFFShape"): offShapes.append(a)
		else:
			if a.name.begins_with("ONShape"):
				onShapes.append(a)
				a.set_meta("ONShape", true)
			elif a.name.begins_with("OFFShape"):
				offShapes.append(a)
				a.set_meta("OFFShape", true)
		)
	_reset_shapes()
	if Engine.is_editor_hint():
		var testSceneParent = get_tree().edited_scene_root
		if testSceneParent.has_node("Player"): return
		sceneParent = testSceneParent
	else:
		_setup_areas()

## Setups areas to be used during execution.
func _setup_areas() -> void:
	onShapes.map(func(a: CollisionShape3D): _make_area(a, "on"))
	offShapes.map(func(a: CollisionShape3D): _make_area(a, "off"))

## Resets debug shapes.
func _reset_shapes() -> void:
	if len(onShapes) == 0: add_shape("ONShape")
	if len(offShapes) == 0: add_shape("OFFShape")

## Adds collision shape.
func add_shape(shape: String) -> void:
	var currentShape: CollisionShape3D = CollisionShape3D.new()
	add_child(currentShape)
	currentShape.set_meta(shape, true)
	currentShape.name = shape
	currentShape.debug_color = DEBUGCOLORS.get(shape)
	if Engine.is_editor_hint(): currentShape.owner = get_tree().edited_scene_root
	get(shape.to_camel_case() + "s").append(currentShape)

## Executed on every frame.
func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): 
		var testSceneParent = get_tree().edited_scene_root
		if testSceneParent == sceneParent: return
		if testSceneParent.has_node("Player"): return
		sceneParent = testSceneParent

## Makes detection areas.
func _make_area(shape: CollisionShape3D, mode: String) -> void:
	var area: Area3D = Area3D.new()
	if mode == "on": 
		onAreas.append(area)
		area.body_entered.connect(_on_body_entered.bind(true))
	else: 
		offAreas.append(area)
		area.body_entered.connect(_on_body_entered.bind(false))
	area.name = "Area_" + shape.name
	add_child(area)
	shape.reparent(area)
	area.monitorable = false
	area.monitoring = true
	area.set_collision_mask_value(1, false)
	area.set_collision_mask_value(2, true)

## On player entering node
func _on_body_entered(body: Node, mode: bool) -> void:
	if body is not Player: return
	if mode == isActive: return
	if forceMode != ForceModes.OFF: return
	do_show_hide(mode)
	isActive = mode
	GeneralVariables.saveManager.store_change(self, sceneParent)

## Restores save.
func restore_save(mode: bool) -> void:
	isActive = mode
	do_show_hide(mode)

## Shows and hides what's been setup.
func do_show_hide(mode: bool) -> void:
	for object in hideObjects: if object: object.set_deferred("visible", not mode)
	for object in showObjects: if object: object.set_deferred("visible", mode)

## Forces a mode.
func force_mode(mode: bool) -> void:
	if mode: forceMode = ForceModes.TRUE
	else: forceMode = ForceModes.FALSE
	do_show_hide(mode)
	isActive = mode
	GeneralVariables.saveManager.store_change(self, sceneParent)
