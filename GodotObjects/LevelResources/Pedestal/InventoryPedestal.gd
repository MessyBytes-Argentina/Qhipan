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

## Reference to the pedestal wall.
@onready var mesh: MeshInstance3D = %Wall
## Sticker highlight sprite reference
@onready var highlight: Sprite3D = %Highlight
@onready var placedSticker: MeshInstance3D = %PlacedSticker

var playerInArea: Player
## Tween for the highlight bobbing animation
var stickerHighlightTween: Tween
var playerHasSticker: bool = false
@onready var area: Area3D = %Area3D

## Executed when node first enters scene tree.
func _ready() -> void:
	update_texture()
	bob_sticker_hightlight()

func _unhandled_input(event: InputEvent) -> void:
	if not playerInArea: return
	if not event.is_action_pressed("interact"): return
	if not playerHasSticker: return
	var sticker: PocketSticker = GeneralVariables.inventory.remove_sticker(pedestalName)
	highlight.hide()
	stickerHighlightTween.kill()
	highlight.queue_free()
	activate_pedestal()
	var material: StandardMaterial3D = placedSticker.get_surface_override_material(0).duplicate()
	material.albedo_texture = sticker.image
	placedSticker.set_surface_override_material(0, material)
	placedSticker.show()
	playerInArea.grabArea.canDrop = true
	playerInArea.grabArea.canGrab = true
	playerInArea = null
	area.set_deferred("monitoring", false)
	await get_tree().process_frame
	area.queue_free()

## Activates pedestal.
func activate_pedestal() -> void:
	get_tree().call_group("Metaprogression", "pedestal_activated", pedestalName)

## Updates debug texture.
func update_texture() -> void:
	var material: ShaderMaterial = mesh.get_surface_override_material(0).duplicate()
	material.set_shader_parameter("top_texture_albedo", texture)
	material.set_shader_parameter("bottom_texture_albedo", texture)
	material.set_shader_parameter("side_texture_albedo", texture)
	mesh.set_surface_override_material(0, material)

func _on_player_entered(body: Node3D) -> void:
	if body is not Player: return
	playerInArea = body
	playerInArea.grabArea.canDrop = false
	playerInArea.grabArea.canGrab = false
	playerHasSticker = GeneralVariables.inventory.has_sticker(pedestalName) != null
	if playerHasSticker:
		highlight.show()

func _on_player_exited(body: Node3D) -> void:
	if body != playerInArea: return
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
