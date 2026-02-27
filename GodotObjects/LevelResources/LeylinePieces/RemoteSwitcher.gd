extends Node
## Handles turning on or off referenced nodes. Useful for objects with multiple leylines.
class_name RemoteSwitcher

## List of objects to remotely switch.
@export var attachedObjects: Array[Node] = []

## Switches state.
func switch_state() -> void:
	for child in attachedObjects: 
		if child is AlternatingObject or child is MovingPlatform or child is LitGlass or child is LeylinePiece or child is RemoteSwitcher: 
			child.switch_state()
