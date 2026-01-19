extends SubViewportContainer

## Placegolder sticker book for animating sticker inventory.
class_name StickerBook

## Default position to drop stickers in.
const DEFAULTSTICKERPOS: Vector3 = Vector3(-1.0, 0.0, 4.5)

## Signals that the animation finished.
signal animation_finished(animationName: StringName)

## Reference to the animation player.
@onready var animationPlayer: AnimationPlayer = %AnimationPlayer
## Reference to all 4 placeholder stickers.
@onready var stickers: Array[Sprite3D] = [%Sticker1, %Sticker2, %Sticker3, %Sticker4]

## The animation queue, for playing animations back to back.
var animationQueue: Array[String] = []

## Executed when node first enters the scene tree.
func _ready() -> void:
	animationPlayer.animation_finished.connect(_animation_finished)

## Called when a sticker is added to the inventory.
func sticker_added() -> void:
	update_stickers()
	show_book()
	animate_sticker()
	hide_book()

## Called when a sticker is removed from the inventory.
func sticker_removed(sticker: PocketSticker) -> void:
	show_book()
	animate_sticker_out(sticker)
	hide_book()
	update_stickers()

## Updates sticker images.
func update_stickers() -> void:
	for i in 4:
		if len(GeneralVariables.inventory.currentInventory) > i:
			stickers[i].texture = GeneralVariables.inventory.currentInventory[i].image
		else:
			stickers[i].position = DEFAULTSTICKERPOS

## Shows the book.
func show_book() -> void:
	play_animation("Open")

## Hides the book.
func hide_book() -> void:
	play_animation("Close")

## Animates sticking a sticker.
func animate_sticker() -> void:
	play_animation("Sticker" + str(len(GeneralVariables.inventory.currentInventory)))

## Animates removing a sticker.
func animate_sticker_out(sticker: PocketSticker) -> void:
	play_animation("Sticker" + str(stickers.find_custom(func(a: Sprite3D): return a.texture == sticker.image) + 1) + "_remove")

## Plays an animation or adds it to the queue.
func play_animation(animation: String) -> void:
	if animationPlayer.is_playing():
		if len(animationQueue) > 0:
			if animationQueue[len(animationQueue) - 1] == animation: return
			if animation == "Close":
				if animationQueue[len(animationQueue) - 1] == "Open": animationQueue.pop_back(); return
			elif animation == "Open":
				if animationQueue[len(animationQueue) - 1] == "Close": animationQueue.pop_back(); return
		animationQueue.append(animation)
	else:
		animationPlayer.play(animation)

## Plays next animation and notifies that an animation is finished playing.
func _animation_finished(animation: StringName) -> void:
	animation_finished.emit(animation)
	if len(animationQueue) > 0:
		animationPlayer.play(animationQueue.pop_front())
