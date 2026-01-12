extends SubViewportContainer

class_name StickerBook

const DEFAULTSTICKERPOS: Vector3 = Vector3(-1.0, 0.0, 4.5)
const SHOWSTICKERTIME: float = 0.5

@onready var animationPlayer: AnimationPlayer = %AnimationPlayer
@onready var stickers: Array[Sprite3D] = [%Sticker1, %Sticker2, %Sticker3, %Sticker4]

func sticker_added() -> void:
	update_stickers()
	await show_book()
	await animate_sticker()
	await  get_tree().create_timer(SHOWSTICKERTIME).timeout
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
	animationPlayer.play("Open")
	await animationPlayer.animation_finished

func hide_book() -> void:
	animationPlayer.play("Close")
	await animationPlayer.animation_finished

func animate_sticker() -> void:
	animationPlayer.play("Sticker" + str(len(GeneralVariables.inventory.currentInventory)))
	await animationPlayer.animation_finished
