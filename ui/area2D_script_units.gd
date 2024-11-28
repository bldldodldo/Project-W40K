extends Area2D

# Define custom signals
signal mouse_over_it(comb_name: String)
signal mouse_clicked(comb_name: String)
signal mouse_out_of_it(comb_name: String)

func _ready():
	# Connect the built-in signals to custom methods
	connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	connect("mouse_exited", Callable(self, "_on_mouse_exited"))
	connect("input_event", Callable(self, "_on_input_event"))

# Emit signal when the mouse is over the Area2D
func _on_mouse_entered():
	var _Node2D = self.get_parent().get_parent()
	emit_signal("mouse_over_it", _Node2D.name)
	#apply_outline(Color(1,1,1,1))

# Handle mouse leaving the Area2D (optional for additional logic)
func _on_mouse_exited():
	var _Node2D = self.get_parent().get_parent()
	emit_signal("mouse_out_of_it", _Node2D.name)

# Emit signal when the Area2D is clicked
func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		#var _controller = get_node("/root/Game/Controller")
		#if not _controller._skill_selected and _controller.controlled_combatant == {}:
		var _Node2D = self.get_parent().get_parent()
		emit_signal("mouse_clicked", _Node2D.name)
		
		
func apply_outline(color: Color, size: float = 1):
	if not self.get_parent() or not self.get_parent() is Sprite2D:
		print("Error: The provided Area2D does not have a parent Sprite2D.")
		return
	var sprite = self.get_parent() as Sprite2D
	if not sprite.material:
		sprite.material = ShaderMaterial.new()
	var material = sprite.material as ShaderMaterial
	material.shader = preload("res://shaders/character_outline.gdshader")
	material.set_shader_parameter("color", color)
	material.set_shader_parameter("thickness", size)
	print("Outline applied to Sprite2D: ", sprite.name)
	
func remove_outline():
	if not self.get_parent() or not self.get_parent() is Sprite2D:
		print("Error: The provided Area2D does not have a parent Sprite2D.")
		return
	var sprite = self.get_parent() as Sprite2D
	if sprite.material:
		sprite.material = null  # Remove the ShaderMaterial
	print("Outline removed for Sprite2D: ", sprite.name)
