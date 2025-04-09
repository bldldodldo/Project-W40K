extends TileMapLayer

@export var tile_map: TileMapLayer

# Define the tile IDs for the checkerboard pattern
var tile_a = 1  # Replace with the ID of your first tile
var tile_b = 2  # Replace with the ID of your second tile


func _ready():
	fill_checkerboard_walls()

func fill_checkerboard_walls():
	var used_cells = get_used_cells()
	for vec in used_cells:
			var tile_id = tile_a if (vec.x + vec.y) % 2 == 0 else tile_b
			tile_map.set_cell(vec, tile_id, Vector2i(0,0))
