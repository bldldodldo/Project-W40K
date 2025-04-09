extends Node2D
var lines_to_draw = []

func add_line(pos1: Vector2, pos2: Vector2, col: Color = Color(1, 1, 1, 1), mov: Vector2 = Vector2(0,0)):
	lines_to_draw.append({"position1": pos1, "position2": pos2, "color": col, "movement": mov})
	queue_redraw()  # Force redraw

func _draw():
	for item in lines_to_draw:
		draw_line(Vector2(0,0), item.position2 - item.position1, item.color, 20)
		self.position = item.position1
		lines_to_draw.pop_front()
