@tool
extends Node3D
## This element loads a new scene into the main scene container.
class_name ChunkLoadingHotspot

## Visual data for the sphere.
const VISUALSPHEREDATA: Dictionary[String, Variant] = {"color": Color.PURPLE * Color(Color.WHITE, 0.85), "radius": 0.25}
## Visual data for the colliders.
const DEBUGCOLORS: Dictionary[String, Color] = {"LoadShape": Color.ORANGE * Color(Color.WHITE, 0.5), "UnloadShape": Color.CRIMSON * Color(Color.WHITE, 0.5)}
## Tiem to wait on previsualizing scene position.
const PREVIEWTIME: float = 20

## The name of the hotspot. This is used to identify where to spawn scenes.
@export var hotspotName: String
## Path to the scene to load.
@export_file_path("*.tscn") var sceneToLoad: String:
	set(value):
		sceneToLoad = value
		if Engine.is_editor_hint() and is_node_ready(): loadedScene = null
## Buton to test for the current positioning of scenes.
@export_tool_button("Test Position", "Debug") var testPosition: Callable = test_position 
## Buton to test for the current positioning of scenes.
@export_tool_button("Add Load Shape", "BoxShape3D") var addLoadShape: Callable = add_shape.bind("LoadShape") 
## Buton to test for the current positioning of scenes.
@export_tool_button("Add Unload Shape", "BoxMesh") var addUnloadShape: Callable = add_shape.bind("UnloadShape")
## Group to hide storage only variables because export storage doesn't seem to do the thing.
@export_group("Root Reference")
## Reference to the scene root.
@export var rootNode: Node

## Reference to the Area3Ds used to load the new scene.
var loadAreas: Array[Area3D]
## Reference to the Area3Ds used to unload the new scene.
var unloadAreas: Array[Area3D]
## Reference to the CollisionShape3Ds used to load the new scene.
var loadShapes: Array[CollisionShape3D] = []
## Reference to the CollisionShape3Ds used to unload the new scene.
var unloadShapes: Array[CollisionShape3D] = []
## Reference to the loaded scene.
var loadedScene: Node = null
## Reference to the loaded scene's matching hotspot.
var loadedHotspot: ChunkLoadingHotspot

## Executed when node first enters the scene tree.
func _ready() -> void:
	var children: Array[Node] = get_children()
	children.map(func(a: Node): 
		if a.has_meta("LoadShape"): loadShapes.append(a) 
		elif a.has_meta("UnloadShape"): unloadShapes.append(a)
		else:
			if a.name == "LoadShape":
				loadShapes.append(a)
				a.set_meta("LoadShape", true)
			elif a.name == "UnloadShape":
				loadShapes.append(a)
				a.set_meta("UnloadShape", true)
		)
	_reset_shapes()
	if Engine.is_editor_hint():
		_show_sphere()
		rootNode = get_tree().edited_scene_root
	else:
		_setup_areas()

## Resets debug shapes.
func _reset_shapes() -> void:
	add_to_group("ChunkLoadingHotspots", true)
	if len(loadShapes) == 0: add_shape("LoadShape")
	if len(unloadShapes) == 0: add_shape("UnloadShape")

func add_shape(shape: String) -> void:
	var currentShape: CollisionShape3D = CollisionShape3D.new()
	add_child(currentShape)
	currentShape.set_meta(shape, true)
	currentShape.name = shape
	currentShape.debug_color = DEBUGCOLORS.get(shape)
	if Engine.is_editor_hint(): currentShape.owner = get_tree().edited_scene_root
	get(shape.to_camel_case()).append(currentShape)

## Shows debug sphere.
func _show_sphere() -> void:
	var visualInstance: MeshInstance3D = MeshInstance3D.new()
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = VISUALSPHEREDATA.radius
	sphere.height = VISUALSPHEREDATA.radius * 2.0
	var material: ORMMaterial3D = ORMMaterial3D.new()
	material.albedo_color = VISUALSPHEREDATA.color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	sphere.material = material
	visualInstance.mesh = sphere
	add_child(visualInstance)

## Setups areas to be used during execution.
func _setup_areas() -> void:
	loadShapes.map(func(a: CollisionShape3D): _make_area(a, "load"))
	unloadShapes.map(func(a: CollisionShape3D): _make_area(a, "unload"))

## Makes detection areas.
func _make_area(shape: CollisionShape3D, mode: String) -> void:
	var area: Area3D = Area3D.new()
	if mode == "load": 
		loadAreas.append(area)
		area.body_entered.connect(_start_load.unbind(1))
	else: 
		unloadAreas.append(area)
		area.body_entered.connect(_do_unload.unbind(1))
	area.name = "Area_" + shape.name
	add_child(area)
	shape.reparent(area)
	area.monitorable = false
	area.monitoring = true
	area.set_collision_mask_value(1, false)
	area.set_collision_mask_value(2, true)

## Loads new scene into preselected location.
func _start_load() -> void:
	if loadedScene: return
	ResourceLoader.load_threaded_request(sceneToLoad, "PackedScene", true)
	while ResourceLoader.load_threaded_get_status(sceneToLoad) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
	if ResourceLoader.load_threaded_get_status(sceneToLoad) in [ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE]:
		push_error("An error occurred while loading scene '" + sceneToLoad + "'.")
		return
	loadedScene = ResourceLoader.load_threaded_get(sceneToLoad).instantiate()
	rootNode.get_parent().add_child(loadedScene)
	loadedScene.set_meta("isRoot", true)
	set_hotspot_position()
	loadedHotspot.loadedHotspot = self
	loadedHotspot.loadedScene = rootNode
	GeneralVariables.saveManager.request_scene_load(loadedScene)

## Unloads scene.
func _do_unload() -> void:
	if not loadedScene: return
	loadedScene.queue_free()
	loadedScene = null
	loadedHotspot = null

## Shows the packed scene for checking alignment
func test_position() -> void:
	if loadedScene == null:
		loadedScene = load(sceneToLoad).instantiate()
	add_child(loadedScene)
	set_hotspot_position()
	await get_tree().create_timer(PREVIEWTIME).timeout
	remove_child(loadedScene)

## Aligns scene to match hotspots.
func set_hotspot_position() -> void:
	loadedScene.global_position = Vector3.ZERO
	var hotspots: Array[Node] = get_tree().get_nodes_in_group("ChunkLoadingHotspots")
	hotspots = hotspots.filter(func(a: ChunkLoadingHotspot): return a.hotspotName == hotspotName and a != self)
	loadedHotspot = hotspots[0]
	if len(hotspots) > 0: loadedScene.global_position = -loadedHotspot.global_position + global_position
