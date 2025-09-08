extends Area3D

class_name AntiStickerArea

var pickupHandler: PickupHandler

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	var player: Player = get_tree().get_first_node_in_group("Player")
	while not player:
		player = get_tree().get_first_node_in_group("Player")
		await get_tree().process_frame
	if not player.is_node_ready(): await player.ready
	pickupHandler = player.grabArea

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		if pickupHandler.pickupOnHand: pickupHandler.drop()
		pickupHandler.inNoStickerArea = true

func _on_body_exited(body: Node3D) -> void:
	if body is not Player: return
	pickupHandler.inNoStickerArea = false
