extends GridMap

## This class handles processing and reporting valid terrain pieces to paste stickers into.
class_name StickerGridmap

## The valid faces for each piece type.
const VALIDFACES: Dictionary[String, PackedVector3Array] = {
	"CornerRemovedUpsideDown": [Vector3.UP, Vector3.LEFT, Vector3.FORWARD],
	"CornerRemoved": [Vector3.LEFT, Vector3.FORWARD],
	"Cube": [Vector3.UP, Vector3.LEFT, Vector3.FORWARD, Vector3.RIGHT, Vector3.BACK],
	"RampUpsideDown": [Vector3.UP, Vector3.RIGHT],
	"Ramp": [Vector3.RIGHT],
	"SlabCornerRemovedUpsideDown": [Vector3.UP],
	"SlabRampUpsideDown": [Vector3.UP],
	"Slab": [Vector3.UP],
	"Wedge": [Vector3.RIGHT, Vector3.BACK]
}

## The list of names of the terrain types a sticker can be placed on.
@export var stickerValidTerrainTypes: PackedStringArray

## The list of stickerable surfaces.
var stickerableSurfaces: Dictionary[Vector3, Vector3] = {}

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	fetch_stickerable_surfaces()

## Fetches all valid stickerable surfaces.
func fetch_stickerable_surfaces() -> void:
	# Fetch valid materials and pointing vectors.
	var stickerableMaterials: Dictionary[int, Array]
	for material in mesh_library.get_item_list():
		var currentMaterialConstruct: PackedStringArray = mesh_library.get_item_name(material).split("__")
		if currentMaterialConstruct[1] not in stickerValidTerrainTypes or currentMaterialConstruct[0] not in VALIDFACES.keys(): continue
		stickerableMaterials[material] = VALIDFACES[currentMaterialConstruct[0]]
	# Check for materials in grid and discard occupied faces.
	var usedCells: Array[Vector3i] = get_used_cells()
	for cell in usedCells:
		var cellItem: int = get_cell_item(cell)
		var isSlab: bool = mesh_library.get_item_name(cellItem).contains("Slab")
		if cellItem not in stickerableMaterials.keys(): continue
		for direction in stickerableMaterials[cellItem]:
			var rotatedDirection: Vector3 = direction * get_cell_item_basis(cell).inverse()
			var testDirection: Vector3i = rotatedDirection.normalized()
			if (cell + testDirection) in usedCells or (cell + testDirection + Vector3i.UP) in usedCells: continue
			stickerableSurfaces[to_global(map_to_local(cell)) + ((rotatedDirection / 2.0) if not isSlab else Vector3.ZERO) + cell_size * Vector3.UP] = rotatedDirection
	var grabArea: PickupHandler = get_tree().get_first_node_in_group("Player").grabArea
	while not grabArea:
		await get_tree().process_frame
		grabArea = get_tree().get_first_node_in_group("Player").grabArea
	grabArea._fetch_valid_surfaces()
