extends Area3D
class_name AntiDropArea

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(player_entered)
	body_exited.connect(player_exited)

## Adds this area to the player/grabArea collection
func player_entered(playerBody: Player) -> void:
	playerBody.grabArea.add_anti_drop_area(self)

## Removes this area from the player/grabArea collection
func player_exited(playerBody: Player) -> void:
	playerBody.grabArea.remove_anti_drop_area(self)
