@tool
@icon("uid://jtcedud2gc5m")
extends Node3D
## A valid stickerable surface. If it's in the scene then a sticker can be placed here.
class_name StickerMarker

## Constants for thebug shape of the sticker surface.
const PLACEHOLDERDIRECTION: Dictionary[String, Variant] = {"color": Color.DEEP_PINK * Color(Color.WHITE, 0.85), "radius": 0.25, "height": 0.25}
## Constants for thebug shape of the sticker up direction.
const PLACEHOLDERUP: Dictionary[String, Variant] = {"color": Color.SKY_BLUE * Color(Color.WHITE, 0.85), "radius": 0.1, "height": 0.5}

## Emmited when a sticker is placed or removed
signal sticker(placed: StickerBase)

## Which stickers can be placed here.
@export_flags("Alternator", "Fan", "Key", "Lamp") var validStickers: int = 15
## Scale of the placed sticker.
@export_range(0.0, 5.0, 0.01) var specialStickerScale: float = 1.0
## Special Flags.
@export_flags("noPlayerFan", "NoPlayerAntigravity") var specialFlags: int = 0
## Fan range override.
@export_range(-1, 20, 0.5) var overrideFanLength: float = -1

## Surface data.
var data: StickerableSurfaceData

## Executed when node first enters the scene tree
func _ready() -> void:
	_setup_shape()
	if Engine.is_editor_hint(): return
	await get_tree().process_frame
	print("b")
	_save_data()

## Ties queue free to function.
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			_on_delete_requested()

## Sets up the debug shape.
func _setup_shape() -> void:
	for child in get_children(): child.queue_free()
	if not Engine.is_editor_hint(): return
	var virtualMarker: MeshInstance3D = MeshInstance3D.new()
	var shape: CylinderMesh = CylinderMesh.new()
	shape.top_radius = 0.0
	shape.bottom_radius = PLACEHOLDERDIRECTION.radius
	shape.height = PLACEHOLDERDIRECTION.height
	var material: ORMMaterial3D = ORMMaterial3D.new()
	material.albedo_color = PLACEHOLDERDIRECTION.color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	shape.material = material
	virtualMarker.mesh = shape
	virtualMarker.position.y = PLACEHOLDERDIRECTION.radius / 2.0
	add_child(virtualMarker)
	var virtualUpMarker: MeshInstance3D = MeshInstance3D.new()
	var upShape: CylinderMesh = CylinderMesh.new()
	upShape.top_radius = 0.0
	upShape.bottom_radius = PLACEHOLDERUP.radius
	upShape.height = PLACEHOLDERUP.height
	var upMaterial: ORMMaterial3D = ORMMaterial3D.new()
	upMaterial.albedo_color = PLACEHOLDERUP.color
	upMaterial.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	upShape.material = upMaterial
	virtualUpMarker.mesh = upShape
	virtualUpMarker.rotation.z = -PI / 2.0
	virtualUpMarker.rotation.y = PI / 2.0
	virtualUpMarker.position.z = -PLACEHOLDERUP.height / 2.0
	add_child(virtualUpMarker)

## Exports data to the surface manager.
func _save_data() -> void:
	var mainScene: Node = get_tree().get_first_node_in_group("Player").get_parent()
	mainScene = mainScene.get_child(mainScene.get_child_count() - 1)
	if not mainScene.is_node_ready():
		await mainScene.ready
	await get_tree().process_frame
	var pointingTo: Node3D = Node3D.new()
	pointingTo.position = Vector3.UP
	add_child(pointingTo)
	data = StickerableSurfaceData.new(self, pointingTo)
	while not GeneralVariables.stickerableSurfacesManager:
		await get_tree().process_frame
	GeneralVariables.stickerableSurfacesManager.load_data(data)
	pointingTo.queue_free()

## Called when a sticker is placed or removed.
func sticker_activity() -> void:
	sticker.emit(data.used)

## Runs before it's freed.
func _on_delete_requested() -> void:
	if Engine.is_editor_hint(): return
	GeneralVariables.stickerableSurfacesManager.delete_data(data)
	queue_free()
