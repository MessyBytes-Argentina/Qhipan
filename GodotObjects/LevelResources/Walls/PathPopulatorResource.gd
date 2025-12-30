extends Resource

class_name PathPopulatorResource

## Offset from the begining of the path.
@export_range(0.00, 200.0, 0.01) var offsetStart: float = 0.0
## Offset from the end of the path.
@export_range(0.00, 200.0, 0.01) var offsetEnd: float = 0.0
## Toggles the offset from the end of the path.
@export var useOffsetEnd: bool = false
## Seed to use for randomness. This is so it will look the same in runtime too.
@export_range(1.0, 1000.0, 1.0) var randomSeed: int = 1
