@tool
extends Node3D
class_name ChunkLoadingHotspot

const VISUALSPHEREDATA: Dictionary[String, Variant] = {"color": Color.PURPLE * Color(Color.WHITE, 0.85), "radius": 0.25}
const DEBUGCOLORS: Dictionary[String, Color] = {"LoadShape": Color.ORANGE * Color(Color.WHITE, 0.5), "UnloadShape": Color.CRIMSON * Color(Color.WHITE, 0.5)}
const PREVIEWTIME: float = 5

@export var hotspotName: String
@export_file_path("*.tscn") var sceneToLoad: String:
	set(value):
		sceneToLoad = value
		if Engine.is_editor_hint() and is_node_ready(): loadedScene = null
@export_tool_button("Test Position", "Debug") var testPosition: Callable = test_position 

var loadArea: Area3D
var unloadArea: Area3D
var loadShape: CollisionShape3D
var unloadShape: CollisionShape3D
var loadedScene: Node = null

func _ready() -> void:
	_reset_shapes()
	if Engine.is_editor_hint():
		_show_sphere()
	else:
		_setup_areas()

func _reset_shapes() -> void:
	add_to_group("ChunkLoadingHotspots", true)
	for shape: String in ["LoadShape", "UnloadShape"]:
		if not has_node(shape):
			var currentShape: CollisionShape3D = CollisionShape3D.new()
			set(shape.to_camel_case(), currentShape)
			add_child(currentShape)
			currentShape.name = shape
			currentShape.debug_color = DEBUGCOLORS.get(shape)
			if Engine.is_editor_hint(): currentShape.owner = get_tree().edited_scene_root
		else:
			set(shape.to_camel_case(), get_node(shape))

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

func _setup_areas() -> void:
	for mode in ["load", "unload"]:
		var area: Area3D = Area3D.new()
		set(mode + "Area", area)
		add_child(area)
		get(mode + "Shape").reparent(area)
		area.monitorable = false
		area.monitoring = true
		area.set_collision_mask_value(1, false)
		area.set_collision_mask_value(2, true)
		area.name = mode + "Area"
	loadArea.body_entered.connect(_start_load.unbind(1))
	unloadArea.body_entered.connect(_do_unload.unbind(1))

func _start_load() -> void:
	ResourceLoader.load_threaded_request(sceneToLoad, "PackedScene", true)
	while ResourceLoader.load_threaded_get_status(sceneToLoad) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
	if ResourceLoader.load_threaded_get_status(sceneToLoad) in [ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE]:
		push_error("An error occurred while loading scene '" + sceneToLoad + "'.")
		return
	loadedScene = ResourceLoader.load_threaded_get(sceneToLoad).instantiate()
	get_tree().current_scene.add_child(loadedScene)
	set_hotspot_position()

func _do_unload() -> void:
	print("unload")

func test_position() -> void:
	if loadedScene == null:
		loadedScene = load(sceneToLoad).instantiate()
	add_child(loadedScene)
	set_hotspot_position()
	await get_tree().create_timer(PREVIEWTIME).timeout
	remove_child(loadedScene)

func set_hotspot_position() -> void:
	loadedScene.global_position = Vector3.ZERO
	var hotspots: Array[Node] = get_tree().get_nodes_in_group("ChunkLoadingHotspots")
	hotspots = hotspots.filter(func(a: ChunkLoadingHotspot): return a.hotspotName == hotspotName and a != self)
	if len(hotspots) > 0: loadedScene.global_position = -hotspots[0].global_position + global_position
