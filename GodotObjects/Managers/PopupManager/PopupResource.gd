@tool
extends Resource

## A resource popup. USe this so we don't keep all popups loaded at a time. Used by [PopupManagerObject] to handle queues.
class_name PopupResource

## The popup name.
@export var popupName: String
## The actual popup scene
@export var popupScene: PackedScene:
	set(value):
		if value:
			var tempLoad: Node = value.instantiate()
			if tempLoad is Control:
				popupScene = value
## The color of the background.
@export var greyoutColor: Color = Color(Color.BLACK, 0.25)
## Should the background block mouse inputs? If not I suggest setting up a transparent [param greyoutColor].
@export var greyoutBlocksBackground: bool = true
## Is the popup persisten? Keeps it loaded if needed. Useful for heavier popups that need to remain loaded and positions remembered.
@export var persistent: bool = false
## Animations parameters.
@export_group("Animations")
## Reset animation. Highly recommended.
@export var resetAnimation: Animation
## Pop in animation
@export var popInAnimation: Animation
## Pop out animation
@export var popOutAnimation: Animation

## The loaded scene. Mainly used to keep persistent popups loaded.
var _instantiatedScene: Control

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not Engine.is_editor_hint():
		if persistent:
			_create_scene()

## Returns the scene. Loads it if it's not a persistent popup.
func get_scene() -> Control:
	if not persistent:
		_create_scene()
	return _instantiatedScene

## Creates the scene, handles creating animation player and metadata.
func _create_scene() -> void:
	_instantiatedScene = popupScene.duplicate().instantiate()
	_instantiatedScene.name = popupName
	if popInAnimation or popOutAnimation:
		var animationPlayer: AnimationPlayer = AnimationPlayer.new()
		var animationLibrary: AnimationLibrary = AnimationLibrary.new()
		if popInAnimation:
			animationLibrary.add_animation("popin", popInAnimation.duplicate())
			_instantiatedScene.set_meta("popin", popInAnimation.length)
		if popOutAnimation:
			animationLibrary.add_animation("popout", popOutAnimation.duplicate())
			_instantiatedScene.set_meta("popout", popInAnimation.length)
		if resetAnimation:
			animationLibrary.add_animation("RESET", resetAnimation.duplicate())
		animationPlayer.add_animation_library("", animationLibrary)
		_instantiatedScene.ready.connect(Callable(_instantiatedScene, "add_child").bind(animationPlayer))
		_instantiatedScene.set_meta("animationPlayer", animationPlayer)

## Clears the scene. Just in place to make sure only non-persistent popups get freed from queue.
func clear_scene() -> void:
	if persistent:
		_instantiatedScene.get_parent().remove_child(_instantiatedScene)
	else:
		_instantiatedScene.queue_free()
