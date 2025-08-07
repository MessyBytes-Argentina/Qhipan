extends CharacterBody3D
class_name StickerBase

const BOBBINGSCALE: float = 0.5
const BOBBINGHEIGHT: float = 0.05
const BOBBINGTIME: float = 2.0
const ROTATIONTIME: float = 3.0
const TILTANGLE: float = deg_to_rad(-30)
const GRABHEIGHT: float = 0.6
const PLACEDCHECKTIME: float = 0.25

enum ScaleModes {GRABBED, DROPPED, PLACED}

@export var placed: bool = false
@export var validAreaIndexes: Array[int] = [11]

@onready var areaChecker: Area3D = %AreaChecker
@onready var mesh: MeshInstance3D = %Mesh
@onready var back: MeshInstance3D = %Back
@onready var meshes: Node3D = %Meshes
@onready var shadowDecal: DecalCompatibility = %ShadowDecal
@onready var billboard: Sprite3D = %Billboard

var sceneParent: Node
var onPlayer: bool = false
var rotationTween: Tween
var bobbingTween: Tween
var startSize: Vector2
var meshMaterial: StandardMaterial3D
var backMaterial: StandardMaterial3D

func _ready() -> void:
	sceneParent = get_parent()
	meshMaterial = mesh.get_surface_override_material(0).duplicate(true)
	mesh.set_surface_override_material(0, meshMaterial)
	mesh.mesh = mesh.mesh.duplicate()
	backMaterial = back.get_surface_override_material(0).duplicate()
	back.set_surface_override_material(0, backMaterial)
	startSize = mesh.mesh.size
	shadowDecal.size = Vector3(BOBBINGSCALE, shadowDecal.size.y, BOBBINGSCALE)
	prerender()
	if not placed: 
		set_size(ScaleModes.DROPPED)
		start_rotation()
	else:
		await get_tree().create_timer(PLACEDCHECKTIME).timeout
		var areas: Array[Area3D] = areaChecker.get_overlapping_areas()
		var closest: Area3D
		var shortestDistance: float = 9999999999
		if len(areas) > 0:
			for area in areas:
				var currentDistance: float = global_position.distance_to(area.global_position)
				var hasSticker: bool = area.get_children().any(func(a: Node): return a is StickerBase)
				if currentDistance < shortestDistance and not hasSticker:
					closest = area
					shortestDistance = currentDistance
			if closest and closest.get_collision_layer_value(11):
				place_sticker(closest, closest.get_meta("pointing"))
				return
		set_size(ScaleModes.DROPPED)
		start_rotation()

func prerender() -> void:
	await get_tree().create_timer(0.01).timeout
	mesh.hide()
	back.hide()
	billboard.hide()
	await get_tree().create_timer(0.01).timeout
	mesh.show()
	back.show()
	billboard.show()
	await get_tree().create_timer(0.01).timeout
	billboard.hide()

func place_sticker(area: Area3D, direction: Vector3) -> void:
	set_size(ScaleModes.PLACED)
	global_position = area.global_position + direction * 0.01
	onPlayer = false
	placed = true
	if not Vector3.UP.cross(direction).is_zero_approx():
		look_at(global_position - direction)
	else:
		look_at(global_position - direction, Vector3.FORWARD)
	reparent(area)

func set_size(mode: ScaleModes) -> void:
	match mode:
		ScaleModes.GRABBED:
			billboard.show()
			mesh.hide()
			back.hide()
		ScaleModes.DROPPED:
			billboard.hide()
			mesh.show()
			back.show()
			meshes.scale = Vector3.ONE * BOBBINGSCALE
		ScaleModes.PLACED:
			billboard.hide()
			mesh.show()
			back.show()
			meshes.scale = Vector3.ONE

func grab(node: Node3D) -> void:
	onPlayer = true
	global_position = node.global_position
	global_position.y = global_position.y + GRABHEIGHT
	rotation = Vector3.ZERO
	set_size(ScaleModes.GRABBED)
	stop_rotation()

func drop() -> void:
	set_size(ScaleModes.DROPPED)
	global_position.y = global_position.y - GRABHEIGHT
	onPlayer = false
	placed = false
	reparent(sceneParent)
	start_rotation()

func start_rotation() -> void:
	rotationTween = create_tween()
	bobbingTween = create_tween()
	meshes.position.y = BOBBINGHEIGHT
	meshes.rotation.x = TILTANGLE
	shadowDecal.show()
	bobbingTween.tween_property(meshes, "position:y", -BOBBINGHEIGHT, BOBBINGTIME / 2.0).set_trans(Tween.TRANS_SINE)
	bobbingTween.tween_property(meshes, "position:y", BOBBINGHEIGHT, BOBBINGTIME / 2.0).set_trans(Tween.TRANS_SINE)
	bobbingTween.set_loops()
	bobbingTween.play()
	rotationTween.tween_property(meshes, "rotation:y", deg_to_rad(360), ROTATIONTIME)
	rotationTween.tween_property(meshes, "rotation:y", 0.0, 0.0)
	rotationTween.set_loops()
	rotationTween.play()

func stop_rotation() -> void:
	if rotationTween:
		rotationTween.kill()
	if bobbingTween:
		bobbingTween.kill()
	meshes.position.y = 0
	meshes.rotation.y = 0
	meshes.rotation.x = 0
	meshes.scale = Vector3.ONE
	shadowDecal.hide()
