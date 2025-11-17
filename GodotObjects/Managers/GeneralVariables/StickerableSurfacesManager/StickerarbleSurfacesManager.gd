extends Node
## Manages and notifies of valid stickerable surfaces.
class_name StickerableSurfacesManager

## The loaded surfaces.
var loadedStickerableSurfaces: Array[StickerableSurfaceData]

## Loads an instance of a surface
func load_data(data: StickerableSurfaceData) -> void:
	if loadedStickerableSurfaces.any(func(a: StickerableSurfaceData): return a.node == data.node): return
	loadedStickerableSurfaces.append(data)

## Deletes an instance of a surface
func delete_data(data: StickerableSurfaceData) -> void:
	loadedStickerableSurfaces.erase(data)

## Returns the closest viable surface for a given sticker.
func get_closest_valid_surface(position: Vector3, sticker: StickerBase) -> StickerableSurfaceData:
	var stickerType: int = check_type(sticker)
	var validSurfaces: Array[StickerableSurfaceData] = loadedStickerableSurfaces.filter(func(a: StickerableSurfaceData): return a.validStickers & stickerType and a.used == null)
	if len(validSurfaces) > 0:
		if len(validSurfaces) > 1:
			validSurfaces.sort_custom(func(a: StickerableSurfaceData, b: StickerableSurfaceData): return a.globalPosition.distance_to(position) < b.globalPosition.distance_to(position))
		return validSurfaces[0]
	else: return null

## Returns the surface containing a given sticker.
func get_surface_with_sticker(sticker: StickerBase) -> StickerableSurfaceData:
	var validSurfaces: Array[StickerableSurfaceData] = loadedStickerableSurfaces.filter(func(a: StickerableSurfaceData): return a.used == sticker)
	if len(validSurfaces) > 0:
		return validSurfaces[0]
	return null

## Returns the surface that is on a given position.
func get_surface_with_position(position: Vector3) -> StickerableSurfaceData:
	var validSurfaces: Array[StickerableSurfaceData] = loadedStickerableSurfaces.filter(func(a: StickerableSurfaceData): return a.globalPosition == position)
	if len(validSurfaces) > 0:
		return validSurfaces[0]
	return null

## Returns bitflag for a single sticker type.
func check_type(sticker: StickerBase) -> int:
	if sticker is AlternatorSticker: return 1
	if sticker is FanSticker: return 2
	if sticker is KeySticker: return 4
	if sticker is LampSticker: return 8
	return 0
