@tool
extends Node3D
class_name StickerMarker

const PLACEHOLDERDIRECTION: Dictionary[String, Variant] = {"color": Color.DEEP_PINK * Color(Color.WHITE, 0.85), "radius": 0.25, "height": 0.25}
const PLACEHOLDERUP: Dictionary[String, Variant] = {"color": Color.SKY_BLUE * Color(Color.WHITE, 0.85), "radius": 0.1, "height": 0.5}

signal sticker(placed: bool)

@export_flags("Alternator", "Fan", "Key", "Lamp") var validStickers: int = 15
@export_range(0.0, 5.0, 0.01) var specialStickerScale: float = 1.0

var pointingTo: Node3D
var data: StickerableSurfaceData

func _ready() -> void:
	_setup_shape()
	if Engine.is_editor_hint(): return
	_save_data()

## Ties queue free to function.
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			_on_delete_requested()

func _setup_shape() -> void:
	for child in get_children(): child.queue_free()
	pointingTo = Node3D.new()
	pointingTo.position = Vector3.UP
	add_child(pointingTo)
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

func _save_data() -> void:
	data = StickerableSurfaceData.new()
	data.node = self
	data.direction = global_position.direction_to(pointingTo.global_position)
	data.globalPosition = global_position
	data.validStickers = validStickers
	data.specialScale = Vector3.ONE * specialStickerScale
	while not GeneralVariables.stickerableSurfacesManager:
		await get_tree().process_frame
	GeneralVariables.stickerableSurfacesManager.load_data(data)

func sticker_activity() -> void:
	sticker.emit(data.used != null)

## Runs before it's freed.
func _on_delete_requested() -> void:
	if Engine.is_editor_hint(): return
	GeneralVariables.stickerableSurfacesManager.delete_data(data)
