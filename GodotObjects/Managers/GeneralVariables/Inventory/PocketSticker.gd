extends Resource
## Resource for accumulating all pertinent data for inventory stickers.
class_name PocketSticker

## Sticker name.
@export var name: String
## Sticker image.
@export var image: Texture2D
## Sticker back image.
@export var backImage: Texture2D
## Glow background color.
@export var glowBackgroundColor: Color = Color(Color.WHITE, 0.66)
## Glow background color.
@export var glowRay1Color: Color = Color(Color.WHITE, 0.75)
## Glow background color.
@export var glowRay2Color: Color = Color.WHITE
