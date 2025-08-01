extends CharacterBody3D
class_name StickerBase

const GRABBINGSCALE: float = 0.75
const BOBBINGSCALE: float = 0.5
const BOBBINGHEIGHT: float = 0.05
const BOBBINGTIME: float = 2.0
const ROTATIONTIME: float = 3.0
const TILTANGLE: float = deg_to_rad(-30)
const GRABHEIGHT: float = 0.5

enum ScaleModes {GRABBED, DROPPED, PLACED}

@onready var areaChecker: Area3D = %AreaChecker
@onready var mesh: MeshInstance3D = %Mesh
@onready var back: MeshInstance3D = %Back
@onready var meshes: Node3D = %Meshes
@onready var shadowDecal: DecalCompatibility = %ShadowDecal

var sceneParent: Node
var onPlayer: bool = false
var placed: bool = false
var rotationTween: Tween
var bobbingTween: Tween
var startSize: Vector2
var meshMaterial: StandardMaterial3D
var backMaterial: StandardMaterial3D

func _ready() -> void:
	sceneParent = get_parent()
	meshMaterial = mesh.get_surface_override_material(0).duplicate()
	mesh.set_surface_override_material(0, meshMaterial)
	mesh.mesh = mesh.mesh.duplicate()
	backMaterial = back.get_surface_override_material(0).duplicate()
	back.set_surface_override_material(0, backMaterial)
	startSize = mesh.mesh.size
	shadowDecal.size = Vector3(BOBBINGSCALE, shadowDecal.size.y, BOBBINGSCALE)
	if not placed: 
		set_size(ScaleModes.DROPPED)
		start_rotation()

func place_sticker(pos: Vector3, direction: Vector3) -> void:
	set_size(ScaleModes.PLACED)
	global_position = pos + direction * 0.01
	onPlayer = false
	placed = true
	look_at(global_position - direction)
	reparent(sceneParent)

func set_size(mode: ScaleModes) -> void:
	match mode:
		ScaleModes.GRABBED:
			meshMaterial.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
			backMaterial.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
			mesh.mesh.size = startSize * GRABBINGSCALE
		ScaleModes.DROPPED:
			meshMaterial.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
			backMaterial.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
			mesh.mesh.size = startSize
			meshes.scale = Vector3.ONE * BOBBINGSCALE
		ScaleModes.PLACED:
			meshMaterial.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
			backMaterial.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
			mesh.mesh.size = startSize
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
	bobbingTween.tween_property(meshes, "position:y", -BOBBINGHEIGHT, BOBBINGTIME / 2.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	bobbingTween.tween_property(meshes, "position:y", BOBBINGHEIGHT, BOBBINGTIME / 2.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	bobbingTween.set_loops()
	bobbingTween.play()
	rotationTween.tween_property(meshes, "rotation:y", deg_to_rad(360), ROTATIONTIME)
	rotationTween.tween_property(meshes, "rotation:y", 0.0, 0.0)
	rotationTween.set_loops()
	rotationTween.play()

func stop_rotation() -> void:
	rotationTween.kill()
	bobbingTween.kill()
	meshes.position.y = 0
	meshes.rotation.y = 0
	meshes.rotation.x = 0
	meshes.scale = Vector3.ONE if not onPlayer else (Vector3.ONE * GRABBINGSCALE)
	shadowDecal.hide()
