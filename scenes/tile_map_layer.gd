extends TileMapLayer

var textures_to_draw = []

# Define the tile IDs for the checkerboard pattern
var tile_a = 0  # Replace with the ID of your first tile
var tile_b = 66  # Replace with the ID of your second tile

# Define the area to fill (top-left and bottom-right corners)


func _ready():
	fill_checkerboard_walls()

func fill_checkerboard_walls():
	var used_cells = get_used_cells()
	for vec in used_cells:
			var tile_id = tile_a if (vec.x + vec.y) % 2 == 0 else tile_b
			set_cell(vec, tile_id, Vector2i(0,0))


func add_texture(tex: Texture, pos: Vector2, col: Color = Color(1, 1, 1, 1)):
	textures_to_draw.append({"texture": tex, "position": pos, "color": col})
	queue_redraw()  # Force redraw

func _draw():
	for item in textures_to_draw:
		draw_texture(item.texture, item.position, item.color)
		textures_to_draw.pop_front()
