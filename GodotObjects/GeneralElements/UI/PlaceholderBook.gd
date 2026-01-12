extends SubViewportContainer

class_name StickerBook

const DEFAULTSTICKERPOS: Vector3 = Vector3(-1.0, 0.0, 4.5)
const SHOWSTICKERTIME: float = 0.5

@onready var animationPlayer: AnimationPlayer = %AnimationPlayer
@onready var stickers: Array[Sprite3D] = [%Sticker1, %Sticker2, %Sticker3, %Sticker4]

var animationQueue: Array[String] = []

func _ready() -> void:
	animationPlayer.animation_finished.connect(_animation_finished)

func sticker_added() -> void:
	update_stickers()
	show_book()
	animate_sticker()
	hide_book()

#func sticker_removed() -> void:
	#update_stickers()
	#await show_book()
	#await animate_sticker()
	#hide_book()

func update_stickers() -> void:
	for i in 4:
		if len(GeneralVariables.inventory.currentInventory) > i:
			stickers[i].texture = GeneralVariables.inventory.currentInventory[i].image
		else:
			stickers[i].position = DEFAULTSTICKERPOS

func show_book() -> void:
	play_animation("Open")

func hide_book() -> void:
	play_animation("Close")

func animate_sticker() -> void:
	play_animation("Sticker" + str(len(GeneralVariables.inventory.currentInventory)))

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

func _animation_finished(_animation: StringName) -> void:
	if len(animationQueue) > 0:
		animationPlayer.play(animationQueue.pop_front())
