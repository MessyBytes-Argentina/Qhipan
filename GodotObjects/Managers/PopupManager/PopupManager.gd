extends CanvasLayer

## This scene manages loading, showing, and hiding popups.
class_name PopupManagerObject

## The location to find the resource group for the popup resources to load at start.
const PopupsResourceGroup: String = "uid://b6vq5y04cq4o7"

## The lsit of popups to import.
var popupResources: Dictionary = {}
## The actual queue of popups in screen.
var popupQueue: Array[ColorRect] = []
## The list of afterloaded popups.
var afterloadedPopups: Dictionary = {}

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not Engine.is_editor_hint():
		process_mode = PROCESS_MODE_ALWAYS
		# Make sure this scene is the top layer.
		await get_tree().create_timer(0.1).timeout
		var parent: Node = get_parent()
		parent.remove_child(self)
		parent.add_child(self)
		_load_popup_resources()

## Loads all the [PopupResource]s listed in the provided [prop PopupsResourceGroup].
func _load_popup_resources() -> void:
	var resourceGroup: ResourceGroup = load(PopupsResourceGroup)
	for resource in resourceGroup.load_all():
		if resource is PopupResource:
			var popupResource: PopupResource = resource
			popupResources[popupResource.popupName] = popupResource

## Loads all the [PopupResource]s listed in the provided ResourceGroup. This is used for on demand load.
func load_popups(resourceGroup: ResourceGroup, instanceName: String) -> void:
	afterloadedPopups[instanceName] = []
	resourceGroup.load_all_in_background(_popup_load_finished.bind(instanceName))

## Files the loaded poup resource into [param afterloadedPopups] and [param popupResources].
func _popup_load_finished(popupResource: ResourceGroupBackgroundLoader.ResourceLoadingInfo, instanceName: String) -> void:
	afterloadedPopups[instanceName].append(popupResource.resource.popupName)
	popupResources[popupResource.resource.popupName] = popupResource.resource

## Unloads all popups from a given instanceName.
func unload_popups(instanceName: String) -> void:
	if instanceName in afterloadedPopups:
		for popup in afterloadedPopups[instanceName]:
			popupResources.erase(popup)
		afterloadedPopups.erase(instanceName)

## Loads a popup by name and shows it.
func show_popup(popupName: String) -> void:
	if popupName in popupResources:
		var popupResource: PopupResource = popupResources[popupName]
		var colorRect: ColorRect = ColorRect.new()
		var popupScene: Control = popupResource.get_scene()
		if popupScene.has_meta("popin"):
			colorRect.self_modulate = Color.TRANSPARENT
		colorRect.name = popupResource.popupName
		colorRect.set_anchors_preset(Control.PRESET_FULL_RECT)
		if popupResource.greyoutBlocksBackground:
			colorRect.mouse_filter = Control.MOUSE_FILTER_STOP
		else:
			colorRect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		colorRect.set_meta("popupResource", popupResource)
		add_child(colorRect)
		colorRect.color = popupResource.greyoutColor
		popupScene.hide()
		colorRect.add_child(popupScene)
		if popupScene.has_meta("animationPlayer"):
			var animationPlayer: AnimationPlayer = popupScene.get_meta("animationPlayer")
			if popupResource.resetAnimation:
				animationPlayer.play("RESET")
			await get_tree().create_timer(0.1).timeout
			popupScene.show()
			popupQueue.append(colorRect)
			if popupScene.has_meta("popin"):
				var tweener: Tween = create_tween()
				tweener.tween_property(colorRect, "self_modulate", Color.WHITE, popupScene.get_meta("popin"))
				tweener.play()
				animationPlayer.play("popin")
		else:
			popupScene.show()

## Closes the popup at the top of the queue.
func close_top_popup() -> void:
	if len(popupQueue) > 0:
		var toClose: ColorRect = popupQueue.pop_back()
		_close_popup(toClose)

## Closes the popup at the bottom of the queue.
func close_bottom_popup() -> void:
	if len(popupQueue) > 0:
		var toClose: ColorRect = popupQueue.pop_front()
		_close_popup(toClose)

## Closes a popup passed down by reference. Useful for close buttons (call this method from a signal passing the parent popup as reference).
func close_popup_by_reference(popup: Control) -> void:
	if popup:
		var toClose: ColorRect = popup.get_parent()
		if toClose in popupQueue:
			popupQueue.erase(toClose)
			_close_popup(toClose)

## Closes a popup passed down by name. If from back is true then it closes the bottommost popup of said name, else the topmost one.
func close_popup_by_name(popupName: String, fromBack: bool = false) -> void:
	var toClose: ColorRect
	var allFoundPopups: Array = popupQueue.map(func(a): return a.get_meta("popupResource").popupName == popupName)
	if true in allFoundPopups:
		if fromBack:
			toClose = popupQueue.pop_at(allFoundPopups.find(true))
		else:
			toClose = popupQueue.pop_at(allFoundPopups.rfind(true))
		_close_popup(toClose)

## Internal close function that handles disconnecting signals, playing animations, and keeping persistent popups loaded.
func _close_popup(toClose: ColorRect) -> void:
	var toClosePopupResource: PopupResource = toClose.get_meta("popupResource")
	var actualPopup: Control = toClose.get_child(0)
	if actualPopup.has_meta("popout"):
		var animationPlayer: AnimationPlayer = actualPopup.get_meta("animationPlayer")
		var tweener: Tween = create_tween()
		tweener.tween_property(toClose, "self_modulate", Color.TRANSPARENT, actualPopup.get_meta("popout"))
		tweener.finished.connect(Callable(toClosePopupResource, "clear_scene"))
		tweener.finished.connect(Callable(toClose, "queue_free"))
		tweener.play()
		animationPlayer.play("popout")
	else:
		toClosePopupResource.clear_scene()
		toClose.queue_free()
