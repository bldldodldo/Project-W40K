extends Node2D

@export var tile_map: TileMapLayer

var textures_to_draw = []

func add_texture(tex: Texture, pos: Vector2, col: Color = Color(1, 1, 1, 1)):
	textures_to_draw.append({"texture": tex, "position": pos, "color": col})
	queue_redraw()  # Force redraw

func _draw():
	for item in textures_to_draw:
		draw_texture(item.texture, item.position, item.color)
		textures_to_draw.pop_front()
