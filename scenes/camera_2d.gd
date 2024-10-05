extends Camera2D

# Zoom speed
var zoom_speed = 200

# Zoom factor (<1 or >1)
var zoom_factor = 1

var is_zooming = false
var is_dezooming = false

# Min and max zoom levels
var min_zoom = Vector2(1, 1)  # Zoomed in
var max_zoom = Vector2(5, 5)   # Default view (prevent zooming out beyond this)
var zoom_limit = Vector2(1, 1)
var zoom_step = 2
var see_limit = Vector2(1, 1)
var see_step = 2
#var position_pile = []

func is_in_interval(value: float, min_val: float, max_val: float) -> bool:
	return value >= min_val and value <= max_val

func _ready():
	# Set initial zoom
	zoom = Vector2(1, 1)

func get_center_camera():
	var res = position
	res = Vector2(get_viewport().get_size()/2)
	return res

func _process(delta):
	
	if is_zooming:
		zoom.x = lerp(zoom.x, zoom.x*zoom_factor, zoom_speed*delta)
		zoom.y = lerp(zoom.y, zoom.y*zoom_factor, zoom_speed*delta)
		if zoom.x > zoom_limit.x :
			is_zooming = false
			zoom = zoom_limit
		elif zoom.y > zoom_limit.y :
			is_zooming = false
			zoom = zoom_limit
	if is_dezooming:
		zoom.x = lerp(zoom.x, zoom.x*zoom_factor, zoom_speed*delta)
		zoom.y = lerp(zoom.y, zoom.y*zoom_factor, zoom_speed*delta)
		if zoom.x < zoom_limit.x :
			is_dezooming = false
			zoom = zoom_limit
		elif zoom.y < zoom_limit.y :
			is_dezooming = false
			zoom = zoom_limit
	
	if Input.is_action_just_pressed("ui_zoom_in") and zoom != max_zoom:
		zoom_factor = 1.01
		is_zooming = true
		var mouse_pos = get_global_mouse_position()
		var viewport_size = Vector2(get_viewport().get_size())
		zoom_limit += Vector2(zoom_step, zoom_step)  # Zoom in
		position = (3*position + mouse_pos)/4
		#position_pile.push_back(position)
		clamp_camera_and_zoom(viewport_size)
	elif Input.is_action_just_pressed("ui_zoom_out") and zoom != min_zoom:
		zoom_factor = 0.99
		is_dezooming = true
		var mouse_pos = get_global_mouse_position()
		var viewport_size = Vector2(get_viewport().get_size())
		zoom_limit -= Vector2(zoom_speed, zoom_speed)  # Zoom out
		#var _next_position = position_pile.pop_back()
		#if _next_position != null:
		#	position = _next_position
		clamp_camera_and_zoom(viewport_size)
		#Input.warp_mouse(viewport_size/2)


	

	# Ensure camera does not show anything outside the default view
	#_constrain_camera()

	# Auto-center when reaching the minimum zoom level
	if zoom == min_zoom:
		
		position = get_viewport().get_size()/2

# Function to constrain the camera position
#func _constrain_camera():
	# Get the size of the viewport
	#var viewport_size = get_viewport().get_size()
	
	# Calculate half the size based on the zoom level
	#var half_size = viewport_size / Vector2i(2 * zoom[0], 2 * zoom[1])
	#position.x = 0
	# Clamp the camera position
	#position.x = clamp(position.x, half_size.x, max_zoom.x * half_size.x)
	#position.y = clamp(position.y, half_size.y, max_zoom.y * half_size.y)
	# Ensure camera doesn't go out of bounds to the left or top
	#position.x = clamp(position.x, half_size.x, viewport_size.x - half_size.x)
	#position.y = clamp(position.y, half_size.y, viewport_size.y - half_size.y)


func clamp_camera_and_zoom(viewport_size):
		# Clamp the zoom value to min and max limits
	zoom.x = clamp(zoom.x, min_zoom.x, max_zoom.x)
	zoom.y = clamp(zoom.y, min_zoom.y, max_zoom.y)

	# Clamp the camera to min and max limits
	position.x = clamp(position.x, viewport_size.x/2, viewport_size.x*(1 - 1/zoom.x)/2)	
	position.y = clamp(position.y, 0, viewport_size.y*(1 - 1/zoom.y))
	

func show_combatant_status_main(comb: Dictionary) -> void:
	pass # Replace with function body.
