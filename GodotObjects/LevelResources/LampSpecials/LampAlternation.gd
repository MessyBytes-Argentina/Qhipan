extends Area3D
## Like surfaces for alternators but used for special lamp puzzles.
class_name LampAlternatingSurface

## Is currently on.
@export var currentState: bool = false

## Reference to the timer used for checks.
@onready var timer: Timer = $Timer

## Reference to the alternable children.
var altChildren: Array[Node] = []
## Reference to any sticked stickers.
var stickers: Array[LampSticker] = []

## Executed when node first enters the scene tree.
func _ready() -> void:
	var children: Array[Node] = recursive_get_children(self)
	for child in children:
		if child.has_meta("SpecialAlternation"):
			altChildren.append(child)

## Gets all children.
func recursive_get_children(parent: Node) -> Array[Node]:
	var children: Array[Node] = parent.get_children()
	for child in children.duplicate():
		children.append_array(recursive_get_children(child))
	return children

## Switches all children.
func switch_children(state: bool) -> void:
	for child in altChildren:
		child.switch_state(state)

## Checks the current state of the surface.
func check_states() -> void:
	if not timer.is_stopped(): return
	var newState: bool = false
	if len(stickers) != 0:
		newState = stickers.any(func(a: StickerBase): return a.placed)
	if newState != currentState:
		currentState = newState
		switch_children(currentState)
	if timer.is_node_ready():
		timer.start()

## Triggers when a sticker is placed.
func _on_sticker_entered(body: Node3D) -> void:
	if body is LampSticker:
		stickers.append(body)
		body.just_placed.connect(check_states.unbind(1))
		check_states()

## Triggers when a sticker is removed.
func _on_sticker_exited(body: Node3D) -> void:
	if body is LampSticker:
		if body not in stickers: return
		if body.just_placed.is_connected(check_states):
			body.just_placed.disconnect(check_states)
		stickers.erase(body)
		check_states()
