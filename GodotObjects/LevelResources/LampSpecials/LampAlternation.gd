extends Area3D
class_name LampAlternatingSurface

@export var currentState: bool = false

@onready var timer: Timer = $Timer

var altChildren: Array[Node] = []
var stickers: Array[LampSticker] = []

func _ready() -> void:
	var children: Array[Node] = recursive_get_children(self)
	for child in children:
		if child.has_meta("SpecialAlternation"):
			altChildren.append(child)

func recursive_get_children(parent: Node) -> Array[Node]:
	var children: Array[Node] = parent.get_children()
	for child in children.duplicate():
		children.append_array(recursive_get_children(child))
	return children

func switch_children(state: bool) -> void:
	for child in altChildren:
		child.switch_state(state)

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

func _on_sticker_entered(body: Node3D) -> void:
	if body is LampSticker:
		stickers.append(body)
		body.just_placed.connect(check_states.unbind(1))
		check_states()

func _on_sticker_exited(body: Node3D) -> void:
	if body is LampSticker:
		if body not in stickers: return
		if body.just_placed.is_connected(check_states):
			body.just_placed.disconnect(check_states)
		stickers.erase(body)
		check_states()
