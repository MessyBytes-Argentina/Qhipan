@tool
extends Area3D
## Class that acts as a removable leyline piece.
class_name LeylineCubeCheck

## The size of the cube shape to create.
const CUBESIZE: float = 0.75
## The debug color for the cube shape.
const CUBEDEBUGCOLOR: Color = Color(Color.CYAN, 0.75)

## Reference to the cube shape.
var cubeShape: CollisionShape3D
## Reference to leyline parent.
var leylineParent: LeylinePiece
## This piece's parent if it's a CubeCheck.
var cubeCheckParent: LeylineCubeCheck
## Collection of child leyline pieces.
var leylineChildren: Array[LeylinePiece] = []
## Collection of LeylineCubeCheck children.
var leylineCubeChildren: Array[LeylineCubeCheck] = []
## Collection of child alternable nodes.
var alternableChildren: Array[Node] = []
## Is receiving energy.
var shouldBeOn: bool = false
## Current state.
var state: bool = false
## Flag that checks if cube is placed.
var isCubeInPlace: bool = false

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	cubeShape = CollisionShape3D.new()
	cubeShape.name = "CubeArea"
	cubeShape.debug_color = CUBEDEBUGCOLOR
	var cube: BoxShape3D = BoxShape3D.new()
	cube.size = Vector3.ONE * CUBESIZE
	cubeShape.shape = cube
	add_child(cubeShape)
	if not Engine.is_editor_hint(): return
	leylineParent = get_parent() if get_parent() is LeylinePiece else null
	cubeCheckParent = get_parent() if get_parent() is LeylineCubeCheck else null
	for child in get_children(): 
		if child is LeylinePiece: leylineChildren.append(child)
		elif child is LeylineCubeCheck: leylineCubeChildren.append(child)
		elif child is AlternatingObject or child is MovingPlatform or child is LitGlass or child is RemoteSwitcher: alternableChildren.append(child)

## What to do once turned on.
func switch_state() -> void:
	if leylineParent or cubeCheckParent: return
	shouldBeOn = !shouldBeOn
	set_mode(shouldBeOn)

## Turns on or off.
func set_mode(mode: bool) -> void:
	if isCubeInPlace:
		animate_cube(mode)
	else:
		if state: animate_cube(false)
		else: state = false

## Turns off via child leyline.
func leyline_child_off() -> void:
	var doOff: bool = true
	doOff = doOff and not leylineChildren.any(func(a: LeylinePiece): return a.progress > 0)
	doOff = doOff and not leylineCubeChildren.any(func(a: Node): return a.state)
	if doOff:
		shouldBeOn = false
		set_mode(false)

## Signals to animate cube.
func animate_cube(mode: bool) -> void:
	var previousState: bool = state
	# ANIMATE CUBE HERE
	state = mode
	animation_finished()

## Animates the last piece first, used for turning off.
func animate_last() -> void:
	if len(leylineChildren) == 0 and len(leylineCubeChildren) == 0: animate_cube(false)
	else: 
		for child in leylineChildren: child.animate_last()
		for child in leylineCubeChildren: child.animate_last()

## Called when cube animation is finished.
func animation_finished() -> void:
	if state: 
		for child in leylineChildren: child.animate()
		for child in leylineCubeChildren: child.animate_cube(true)
		if not Engine.is_editor_hint(): for child in alternableChildren: child.switch_state()
	elif leylineParent:
		leylineParent.animate()
	elif cubeCheckParent:
		cubeCheckParent.leyline_child_off()

## Called when alternating cube stops in this place.
func alternating_cube_finished_moving() -> void:
	isCubeInPlace = true
	if not state: switch_state()

## Called when alternating cube is removed.
func alternating_cube_left() -> void:
	isCubeInPlace = false
	if state: switch_state()
