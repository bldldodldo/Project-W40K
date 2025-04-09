extends Node2D
var textures_to_draw = []

func add_texture(tex: Texture, pos: Vector2, col: Color = Color(1, 1, 1, 1), mov: Vector2 = Vector2(0,0)):
	textures_to_draw.append({"texture": tex, "position": pos, "color": col, "movement": mov})
	queue_redraw()  # Force redraw

func _draw():
	for item in textures_to_draw:
		draw_texture(item.texture, Vector2(0,0), item.color)
		self.position = item.position
		textures_to_draw.pop_front()
