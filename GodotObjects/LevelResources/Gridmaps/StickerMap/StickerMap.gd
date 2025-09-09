extends GridMap

## Type of piece id.
enum Pieces {FLOOR, WALL}

## WallArea Scene for placement of stickers.
@onready var wallArea: PackedScene = load("uid://cl8lu173l7esk")
## FloorArea Scene for placement of stickers.
@onready var floorArea: PackedScene = load("uid://dug0cyolanh64")

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_areas(Pieces.FLOOR)
	add_areas(Pieces.WALL)

## Adds the given type of placement area in the correct position for the blocks.
func add_areas(pieceType: Pieces) -> void:
	var cells: Array[Vector3i] = get_used_cells_by_item(pieceType)
	var area: Area3D = floorArea.instantiate() if pieceType == Pieces.FLOOR else wallArea.instantiate()
	for cell in cells:
		var currentArea: Area3D = area.duplicate()
		add_child(currentArea)
		currentArea.global_position = Vector3(cell) * cell_size + Vector3(1,0,1) * cell_size + (Vector3(0.0, 0.01, 0.0) if pieceType == Pieces.FLOOR else Vector3.ZERO)
		if pieceType == Pieces.FLOOR: continue
		var angle: float = orthogonal_hren(cell)
		currentArea.rotation.y = angle
		currentArea.global_position -= Vector3(0.49, 0.0, 0.0).rotated(Vector3.UP, angle)
		currentArea.set_meta("pointing", Vector3(1.0, 0.0, 0.0).rotated(Vector3.UP, angle))

## Returns the angle that the given cell is facing.
func orthogonal_hren(cell: Vector3) -> float:
	var res: float = 0
	match get_cell_item_orientation(cell):
		0, 1, 2, 3, 4, 8, 9, 12, 14:
			res = 0
		5, 7, 20, 22, 23, 21, 13:
			res = -PI/2
		6, 10, 11:
			res = PI
		15, 16, 17, 18, 19:
			res = PI/2
	return res
