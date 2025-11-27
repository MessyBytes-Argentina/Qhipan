@tool
extends StaticBody3D
## Node handles triggering inventory pedestal events.
class_name InventoryPedestal

## Length of bobbing in the y axis.
const STICKERHIGHLIGHTBOBDISTANCE: float = 0.1
## Amount of time the bobbing animation takes.
const STICKERHIGHLIGHTBOBTIME: float = 0.5

## Debug texture for this pedestal
@export var texture: Texture2D:
	set(value):
		texture = value
		if Engine.is_editor_hint() and is_node_ready(): update_texture()
## Used to identify which objects to trigger
@export var pedestalName: String


## Sticker highlight sprite reference
@onready var highlight: Sprite3D = %Highlight
## Reference to the placed sticker mesh
@onready var placedSticker: MeshInstance3D = %PlacedSticker
## Reference to the area.
@onready var area: Area3D = %Area3D
## Group to hide storage only variables because export storage doesn't seem to do the thing.
@export_group("Root Reference")
## Parent node reference for placement.
@export var sceneParent: Node

## Reference to the pedestal wall.
var wallMesh: MeshInstance3D
## Is the player inside the area.
var playerInArea: Player
## Tween for the highlight bobbing animation
var stickerHighlightTween: Tween
## check for whether the player has the required sticker in the inventory
var playerHasSticker: bool = false
## The placed sticker
var sticker: PocketSticker

## Executed when node first enters scene tree.
func _ready() -> void:
	if Engine.is_editor_hint(): sceneParent = get_tree().edited_scene_root
	update_texture()
	bob_sticker_hightlight()

## Executed on input.
func _unhandled_input(event: InputEvent) -> void:
	if not playerInArea: return
	if not event.is_action_pressed("interact"): return
	if not playerHasSticker: return
	sticker = GeneralVariables.inventory.remove_sticker(pedestalName)
	activate_pedestal()
	GeneralVariables.saveManager.store_change(self, sceneParent)
	playerInArea.grabArea.canDrop = true
	playerInArea.grabArea.canGrab = true
	playerInArea = null

## Activates pedestal.
func activate_pedestal() -> void:
	get_tree().call_group("Metaprogression", "pedestal_activated", pedestalName)
	highlight.hide()
	stickerHighlightTween.kill()
	highlight.queue_free()
	var material: StandardMaterial3D = placedSticker.get_surface_override_material(0).duplicate()
	material.albedo_texture = sticker.image
	placedSticker.set_surface_override_material(0, material)
	placedSticker.show()
	area.set_deferred("monitoring", false)
	await get_tree().process_frame
	area.queue_free()

## Updates debug texture.
func update_texture() -> void:
	if not has_node("Wall"): return
	wallMesh = get_node("Wall")
	var material: ShaderMaterial = wallMesh.get_surface_override_material(0).duplicate()
	material.set_shader_parameter("top_texture_albedo", texture)
	material.set_shader_parameter("bottom_texture_albedo", texture)
	material.set_shader_parameter("side_texture_albedo", texture)
	wallMesh.set_surface_override_material(0, material)

## Called when the player enters this pedestal's area.
func _on_player_entered(body: Node3D) -> void:
	if body is not Player: return
	playerInArea = body
	playerHasSticker = GeneralVariables.inventory.has_sticker(pedestalName) != null
	if playerHasSticker:
		highlight.show()
		playerInArea.grabArea.canDrop = false
		playerInArea.grabArea.canGrab = false

## Called when the player exits this pedestal's area.
func _on_player_exited(body: Node3D) -> void:
	if body != playerInArea: return
	if playerHasSticker:
		playerInArea.grabArea.canDrop = true
		playerInArea.grabArea.canGrab = true
	playerInArea = null
	highlight.hide()

## Starts the sticker highlight bobbing animation
func bob_sticker_hightlight() -> void:
	stickerHighlightTween = create_tween()
	stickerHighlightTween.tween_property(highlight, "position:y", highlight.position.y, STICKERHIGHLIGHTBOBTIME).set_trans(Tween.TRANS_SINE)
	stickerHighlightTween.tween_property(highlight, "position:y", highlight.position.y + STICKERHIGHLIGHTBOBDISTANCE, STICKERHIGHLIGHTBOBTIME).set_trans(Tween.TRANS_SINE)
	stickerHighlightTween.set_loops()
	stickerHighlightTween.play()
