extends Camera2D

# Zoom speed
var zoom_speed = 5
var move_speed = 5

var is_zooming = false
var is_dezooming = false
var is_moving = false

# Min and max zoom levels
var min_zoom = Vector2(1, 1)  # Zoomed in
var max_zoom = Vector2(5, 5)   # Default view (prevent zooming out beyond this)
var zoom_limit = Vector2(1, 1)
var zoom_margin = 0.001
var zoom_step = 0.2
var move_limit = Vector2(1, 1)
var move_margin = 0.5
var move_step = 2
var position_pile = []

func is_in_interval(value: float, min_val: float, max_val: float) -> bool:
	return value >= min_val and value <= max_val

func _ready():
	# Set initial zoom
	zoom = min_zoom
	position = get_viewport().get_size()/2

func _process(delta):
	
	clamp_camera_and_zoom()
	if is_moving : 
		position.x = lerp(position.x, move_limit.x, move_speed*delta)
		position.y = lerp(position.y, move_limit.y, move_speed*delta)
		if is_in_interval(position.x, move_limit.x - move_margin, move_limit.x + move_margin) and is_in_interval(position.y, move_limit.y - move_margin, move_limit.y + move_margin) :
			is_moving = false
			position = move_limit
	if is_zooming:
		zoom.x = lerp(zoom.x, zoom_limit.x, zoom_speed*delta)
		zoom.y = lerp(zoom.y, zoom_limit.y, zoom_speed*delta)
		if is_in_interval(zoom.x, zoom_limit.x - zoom_margin,  zoom_limit.x + zoom_margin) and is_in_interval(zoom.y,  zoom_limit.y - zoom_margin,  zoom_limit.y + zoom_margin):
			is_zooming = false
			zoom = zoom_limit
	if is_dezooming:
		zoom.x = lerp(zoom.x, zoom_limit.x, zoom_speed*delta)
		zoom.y = lerp(zoom.y, zoom_limit.y, zoom_speed*delta)
		if is_in_interval(zoom.x, zoom_limit.x - zoom_margin,  zoom_limit.x + zoom_margin) and is_in_interval(zoom.y,  zoom_limit.y - zoom_margin,  zoom_limit.y + zoom_margin):
			is_dezooming = false
			zoom = zoom_limit
	
	if Input.is_action_just_pressed("ui_zoom_in") and zoom != max_zoom:
		var mouse_pos_float = Vector2(get_global_mouse_position())
		var viewport_size_float = Vector2(get_viewport().get_size())
		
		var _future_pos = Vector2(1,1)
		_future_pos.x = clamp(mouse_pos_float.x, viewport_size_float.x/(2*zoom.x), viewport_size_float.x*(1 - 1/(2*zoom.x)))
		_future_pos.y = clamp(mouse_pos_float.y, viewport_size_float.y/(2*zoom.y), viewport_size_float.y*(1 - 1/(2*zoom.y)))
		
		zoom_limit += Vector2(zoom_step, zoom_step)  # Zoom in
		is_zooming = true
		move_limit = _future_pos
		is_moving = true
		
		
	elif Input.is_action_just_pressed("ui_zoom_out") and zoom != min_zoom:
		is_dezooming = true
		var mouse_pos = get_global_mouse_position()
		var viewport_size = Vector2(get_viewport().get_size())
		zoom_limit -= Vector2(2*zoom_step, 2*zoom_step)  # Zoom out
		move_limit = (Vector2(get_viewport().get_size()/2) + position)/2



func clamp_camera_and_zoom():
	var viewport_size = get_viewport().get_size()
		# Clamp the zoom value to min and max limits
	zoom_limit.x = clamp(zoom_limit.x, min_zoom.x, max_zoom.x)
	zoom_limit.y = clamp(zoom_limit.y, min_zoom.y, max_zoom.y)
	if Vector2i(position) != Vector2i(get_viewport().get_size()/2) and is_in_interval(zoom.x, min_zoom.x - zoom_margin, min_zoom.x + zoom_margin) and is_in_interval(zoom.y, min_zoom.y - zoom_margin, min_zoom.y + zoom_margin):
		zoom = min_zoom
		position = Vector2(get_viewport().get_size()/2)
	# Clamp the camera to min and max limits
	position.x = clamp(position.x, viewport_size.x/(2*zoom.x), viewport_size.x*(1 - 1/(2*zoom.x)))	
	position.y = clamp(position.y, viewport_size.y/(2*zoom.y), viewport_size.y*(1 - 1/(2*zoom.y)))
	

func show_combatant_status_main(comb: Dictionary) -> void:
	pass # Replace with function body.


func end_phase_ui_update() -> void:
	pass # Replace with function body.
