@tool
extends StickerBase
## Stickers that go into the inventory.
class_name InventorySticker

## If true checks for areas to place after loading.
@export var sticker: PocketSticker:
	set(value):
		sticker = value
		if Engine.is_editor_hint() and is_node_ready(): set_image()
@export_tool_button("Reset Sticker Image", "CanvasItemMaterial") var resetImage: Callable = set_image

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not Engine.is_editor_hint():
		super()
		if not sticker: return
	else:
		if not sticker: return
		meshMaterial = mesh.get_surface_override_material(0).duplicate(true)
		mesh.set_surface_override_material(0, meshMaterial)
		mesh.mesh = mesh.mesh.duplicate()
		backMaterial = back.get_surface_override_material(0).duplicate()
		back.set_surface_override_material(0, backMaterial)
	set_image()

## Sets the image of the sticker to match the one in the [PocketSticker] resource.
func set_image() -> void:
	meshMaterial.albedo_texture = sticker.image.duplicate()
	backMaterial.albedo_texture = sticker.backImage.duplicate()
	billboard.texture = sticker.image.duplicate()
	billboardZoomedOut.texture = sticker.image.duplicate()

## Moves the sticker position to the given node position.
func grab(_node: Node3D) -> void:
	GeneralVariables.inventory.add_sticker(sticker)
	await get_tree().process_frame
	get_tree().get_first_node_in_group("Player").grabArea.pickupOnHand = false
	queue_free()

## Executed on every physics frame.
func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	super(delta)
