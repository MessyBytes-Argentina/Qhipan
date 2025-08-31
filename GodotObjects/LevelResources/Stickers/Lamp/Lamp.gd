extends StickerBase

const LIGHTRANGEGRABED: float = 1.5
const LIGHTRANGEPLACED: float = 3.5
const LIGHTAREAOFEFFECT: float = 3.5
const LIGHTENERGY: float = 1.0
const LIGHTFADETIME: float = 0.3

## The floating mesh with no lighting on.
@onready var floatingMesh: MeshInstance3D = %FloatingMesh
## The light to turn on and of.
@onready var light: OmniLight3D = %Light
## Light area of effect
@onready var lightArea: Area3D = %LightArea
## Player Detector
@onready var playerDetector: Area3D = %PlayerDetector
## Holds top level shapes
@onready var shapes: Node3D = %Shapes

## Reference to the player character
var player: Player
## Reference to the player character darkness manager
var playerDarknessManager: DarknessBlockerModule
## Light animation tween.
var lightTween: Tween
## Last light range.
var lastLightValue: float = 0.0
## Tracks if player inside this lights effect.
var hasPlayer: bool = false

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	light.position.y = -GRABHEIGHT / 2.0
	while not player:
		player = get_tree().get_first_node_in_group("Player")
		await get_tree().process_frame
	playerDarknessManager = player.get_node("DarknessBlockerModule")
	shapes.top_level = true

func _process(_delta: float) -> void:
	if not hasPlayer: return
	if (global_position * Vector3(1.0, 0.0, 1.0)).distance_to(player.global_position * Vector3(1.0, 0.0, 1.0)) > LIGHTAREAOFEFFECT or grabed:
		lightArea.set_collision_mask_value(5, false)
	elif len(playerDarknessManager.darknessAreas) > 0 and len(playerDarknessManager.lightAreaDetectors) == 1:
		lightArea.set_collision_mask_value(5, true)
	else: 
		lightArea.set_collision_mask_value(5, false)

## Changes the current state and visuals to the given mode
func set_size(mode: ScaleModes) -> void:
	super(mode)
	match mode:
		ScaleModes.GRABBED:
			floatingMesh.hide()
			animate_light_fade(LIGHTRANGEGRABED)
			lightArea.set_deferred("monitoring", false)
			lightArea.set_deferred("monitorable", false)
			playerDetector.set_deferred("monitoring", false)
		ScaleModes.DROPPED:
			floatingMesh.show()
			mesh.hide()
			animate_light_fade(0.0)
		ScaleModes.PLACED:
			floatingMesh.hide()
			mesh.show()
			animate_light_fade(LIGHTRANGEPLACED)
			lightArea.set_deferred("monitoring", true)
			lightArea.set_deferred("monitorable", true)
			playerDetector.set_deferred("monitoring", true)
		ScaleModes.ZOOMEDOUT:
			floatingMesh.hide()
	await get_tree().physics_frame
	shapes.global_position = global_position

func animate_light_fade(newValue: float) -> void:
	light.show()
	if lightTween:
		lightTween.kill()
	var energyGoal: float = 0.0 if newValue == 0.0 else LIGHTENERGY
	var goalTime: float = LIGHTFADETIME * inverse_lerp(newValue, lastLightValue, light.omni_range)
	lightTween = create_tween()
	lightTween.tween_property(light, "light_energy", energyGoal, goalTime).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	lightTween.parallel().tween_property(light, "omni_range", newValue, goalTime).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	lightTween.play()
	lastLightValue = newValue
	if newValue == 0.0: lightTween.finished.connect(light.hide)

## Cabeza fix to load visuals
func prerender() -> void:
	mesh.show()
	floatingMesh.show()
	back.show()
	billboard.show()
	billboardZoomedOut.show()
	await get_tree().create_timer(0.01).timeout
	mesh.hide()
	floatingMesh.hide()
	back.hide()
	billboard.hide()
	billboardZoomedOut.hide()
	await get_tree().create_timer(0.01).timeout
	mesh.show()
	floatingMesh.show()
	back.show()
	billboard.show()
	billboardZoomedOut.show()
	await get_tree().create_timer(0.01).timeout
	floatingMesh.show()
	mesh.hide()
	billboard.hide()
	billboardZoomedOut.hide()

## Activates the sticker effect when held by the player
func activate_on_player_effect() -> void:
	_light_body_entered(player)
	_detector_body_entered(player)

## Deactivates the sticker effect when held by the player
func deactivate_on_player_effect() -> void:
	_light_body_exited(player)
	_detector_body_exited(player)

func _light_body_entered(body: Node3D) -> void:
	if body.has_node("DarknessBlockerModule"): 
		body.get_node("DarknessBlockerModule").light_area_entered(self)

func _light_body_exited(body: Node3D) -> void:
	if body.has_node("DarknessBlockerModule"): 
		body.get_node("DarknessBlockerModule").light_area_exited(self)

func _detector_body_entered(body: Node3D) -> void:
	if body is Player: hasPlayer = true
	if body.has_node("DarknessBlockerModule"): 
		body.get_node("DarknessBlockerModule").light_area_detector_entered(self)

func _detector_body_exited(body: Node3D) -> void:
	if body is Player: hasPlayer = false
	if body.has_node("DarknessBlockerModule"): 
		body.get_node("DarknessBlockerModule").light_area_detector_exited(self)
