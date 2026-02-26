extends Node3D

## Materials.
const MATERIALS: Dictionary[String, ShaderMaterial] = {
	"ON": preload("uid://clkgsnc17ue41"),
	"OFF": preload("uid://bgmps1heu1ecu")
}

## Reference to the sticker marker.
@onready var stickerMarker: StickerMarker = %StickerMarker
## Reference to the mesh.
@onready var mesh: MeshInstance3D = %MeshInstance3D

## Alternating group parent.
var groupParent: AlternatingGroup
## Current state.
var isOn: bool = false

## Executed when node first enters the scene tree.
func _ready() -> void:
	var parent = get_parent()
	if parent is AlternatingGroup: 
		groupParent = parent
	else:
		prints(name," isn't in a group")

## Triggered when a sticker is placed or removed.
func _on_sticker(_placed: StickerBase) -> void:
	if stickerMarker.data.used is not AlternatorSticker: return
	groupParent.switch_children()
	isOn = not isOn
	mesh.set_surface_override_material(0, MATERIALS.ON if isOn else MATERIALS.OFF)
