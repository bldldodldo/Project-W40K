extends Node2D
class_name CController
##Class for controlling sprites representing combatants on the tile map

signal movement_changed(movement: int)
signal finished_move
signal target_selection_started()
signal target_selection_finished()
signal combatant_selected(comb: Dictionary)

var controlled_combatant_exists = false
@export var controlled_node: Node2D 
@export var combat: Combat
@export var controlled_combatant: Dictionary
var tile_map : TileMap
var phase_ended = false

var _selected_skill: String

#var movement = 3:
#	set = set_movement,
#	get = get_movement

var _astargrid = AStarGrid2D.new()
#var current_combatant = 0
var _attack_target_position
var _blocked_target_position
var _skill_selected = false

func _unhandled_input(event):	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_released():
				var mouse_position = get_global_mouse_position()
				var mouse_position_i = tile_map.local_to_map(mouse_position)
				var temp_path = find_path(mouse_position_i)
				var comb = get_combatant_at_position(mouse_position_i)
				var local_map = tile_map.map_to_local(mouse_position_i)
				if _skill_selected == true and comb != null and comb.alive:
					target_selected(comb)
				elif comb != null and comb.alive and comb.side == 0:
					set_controlled_combatant(comb)
				elif comb == null and controlled_combatant_exists and controlled_combatant.arrived :
					print(temp_path.size())
					if temp_path.size() - 1 > controlled_combatant.movement:
						controlled_combatant.selected_path = []
						controlled_combatant.next_action_type = "None"
						print("Action canceled for ", controlled_combatant.name)
						controlled_combatant_exists = false
						controlled_combatant = {}
					else:
						controlled_combatant.next_action_type = "Move"
						controlled_combatant.selected_path = temp_path
						print("New path selected for ", controlled_combatant.name)
						controlled_combatant_exists = false
						controlled_combatant = {}
	
	if event is InputEventMouseMotion:
		if _arrived == true:
			var mouse_position = get_global_mouse_position()
			var mouse_position_i = tile_map.local_to_map(mouse_position)
			find_path(mouse_position_i)
			var comb = get_combatant_at_position(mouse_position_i)
			var local_map = tile_map.map_to_local(mouse_position_i)
			if comb != null:
				if comb.side == 1 and comb.alive:
					_attack_target_position = local_map
				else:
					_attack_target_position = null
					_blocked_target_position = local_map
			elif controlled_combatant_exists and mouse_position_i in _blocking_spaces[controlled_combatant.movement_class]:
				_blocked_target_position = local_map
			else:
				_attack_target_position = null
				_blocked_target_position = null


func get_combatant_at_position(target_position: Vector2i):
	for comb in combat.combatants:
		if comb.position == target_position and comb.alive:
			return comb
	return null

var _occupied_spaces = []

var _blocking_spaces = [
	[],#Ground
	[],#Flying
	[]#Mounted
]

func _ready():
	tile_map = get_node("../Terrain/TileMap")
	_astargrid.region = Rect2i(0, 0, 36, 21)
	_astargrid.cell_size = Vector2i(32, 32)
	_astargrid.offset = Vector2(16, 16)
	_astargrid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_astargrid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_astargrid.update()
	
	#build blocking spaces arrays
	for tile in tile_map.get_used_cells(0):
		var tile_blocking = tile_map.get_cell_tile_data(0, tile)
		for block in tile_blocking.get_custom_data("Blocks"):
			_blocking_spaces[block].append(tile)

func combat_start():
	combat.phase = 3
	new_phase_init()

func new_phase_init():
	if combat.phase == 3:
		print("New turn !")
		for comb in combat.combatants:
			comb.movement = comb.movement_max
		combat.phase = 1
	else:
		combat.phase += 1
	print("Phase ", combat.phase)
	controlled_combatant_exists = false
	for comb in combat.combatants:
		comb.next_action_type = "None"
		comb.next_move = []
		comb.selected_path = []

func combatant_added(combatant):
#	_astargrid.set_point_solid(combatant.position, true)
#	_astargrid.set_point_weight_scale(combatant.position, INF)
	_occupied_spaces.append(combatant.position)


func combatant_died(combatant):
#	_astargrid.set_point_solid(combatant.position, false)
	_astargrid.set_point_weight_scale(combatant.position, 1)
	_occupied_spaces.erase(combatant.position)


func set_controlled_combatant(combatant: Dictionary):
	controlled_node = combatant.sprite
	var movement = combatant.movement
	controlled_combatant = combatant
	controlled_combatant_exists = true
	print("Controlled_combatant set !")
	combatant_selected.emit(controlled_combatant)
	update_points_weight(combatant)

func update_points_weight(comb: Dictionary):
	#Update occupied spaces for flying units
	for point in _occupied_spaces:
		if comb.movement_class == 1:
			_astargrid.set_point_weight_scale(point, 1)
		else:
			_astargrid.set_point_weight_scale(point, INF)
	#Update point weights for blocking spaces
	for class_m in range(_blocking_spaces.size()):
		for space in _blocking_spaces[class_m]:
			if controlled_combatant.movement_class == class_m:
				_astargrid.set_point_weight_scale(space, INF)
			else:
				_astargrid.set_point_weight_scale(space, 1)

func get_distance(point1: Vector2i, point2: Vector2i):
	return absi(point1.x - point2.x) + absi(point1.y - point2.y)


var _arrived = true

var _path : PackedVector2Array

var _next_position

var _position_id = 0

var move_speed = 96

var _previous_position : Vector2i

func _process(delta):
	for comb in combat.combatants:
		if comb.arrived == false:
			_next_position = comb.selected_path[comb.selected_path_id]
			var new_position: Vector2i = tile_map.local_to_map(_next_position)
			var _next_position_comb = get_combatant_at_position(new_position)
			#verifying that, if two characters are about to bump into each other, they are not going in opposite directions. 
			if (_next_position_comb == null or (_next_position_comb.arrived == false and _next_position_comb.sprite.position.direction_to(_next_position_comb.selected_path[_next_position_comb.selected_path_id]) != -1*comb.sprite.position.direction_to(_next_position))):
				comb.sprite.position += comb.sprite.position.direction_to(_next_position) * delta * move_speed
				if comb.sprite.position.distance_to(_next_position) < 1 :
		#			_astargrid.set_point_solid(_previous_position, false)
					print(comb.name, " at position ", comb.position, " goes to ", new_position, " occupied by ", get_combatant_at_position(_next_position))
					_occupied_spaces.erase(comb.previous_position)
					_astargrid.set_point_weight_scale(comb.previous_position, 1)
					var tile_cost = get_tile_cost(comb.previous_position, comb)
					comb.sprite.position = _next_position
					comb.position = new_position
					comb.previous_position = new_position
		#			_astargrid.set_point_solid(new_position, true)
					_occupied_spaces.append(new_position)
					update_points_weight(comb)
					var next_tile_cost = get_tile_cost(new_position, comb)
					comb.movement -= tile_cost
					if comb.selected_path_id < comb.selected_path.size() - 1 and comb.movement > 0 and next_tile_cost <= comb.movement:
						comb.selected_path_id += 1
					else:
						finished_move.emit()
						comb.arrived = true
						comb.next_action_type == "None"
						comb.selected_path = []
			else:
				comb.arrived = true
				comb.next_action_type == "None"
				comb.selected_path = []
				
	if phase_ended: 
		if verifying_arrived():
			phase_ended = false
			new_phase_init()

func verifying_arrived():
	var _verifying_arrived = true
	for comb in combat.combatants:
		if not comb.arrived:
			_verifying_arrived = false
	return _verifying_arrived
			
			


#func set_movement(value):
#	movement = value
#	movement_changed.emit(value)


#func get_movement():
#	return movement

#func get_current_combatant():
#	return combatants[current_combatant]

const tiles_to_check = [
	Vector2i.RIGHT,
	Vector2i.UP,
	Vector2i.LEFT,
	Vector2i.DOWN
]
#func ai_process(target_position: Vector2i):
	#find nearest non-solid tile to target_position
#	var current_position = tile_map.local_to_map(controlled_node.position)
#	print(current_position)
#	for tile in tiles_to_check:
#		if !_astargrid.get_point_weight_scale(target_position + tile) > 999999:
#			ai_move(target_position + tile)
#			break
#	return finished_move

func end_phase():
	if verifying_arrived():
		controlled_combatant_exists = false
		for comb in combat.combatants:
			if comb.next_action_type == "Move":
				print(comb.name, " has type Move")
				move_combatant(comb)
		phase_ended = true
			
func wait(seconds):
	var time_passed = 0
	while time_passed < seconds:
		time_passed += get_process_delta_time()  # Increment the time based on frame delta
		await get_tree().process_frame  # Wait for the next frame
	print("Waited for ", seconds, " seconds")

func end_turn():
	for comb in combat.combatants: 
		comb.movement = comb.movement_max

func move_combatant(comb: Dictionary):
	var _path_size = comb.selected_path.size()
	if _path_size > 1 and comb.movement > 0:
		comb.previous_position = comb.position
		comb.selected_path_id = 1
		comb.arrived = false
		print(comb.name, " bouge de ", comb.movement," sur le chemin : ", comb.selected_path)
		queue_redraw()
	

#func ai_move(target_position: Vector2i):
#	var current_position = tile_map.local_to_map(controlled_node.position)
#	find_path(target_position)
#	print(target_position)
#	move_on_path(current_position)


func find_path(tile_position: Vector2i):
	if controlled_combatant_exists:
		var current_position = tile_map.local_to_map(controlled_node.position)
	#	print(current_position)
	#	print(tile_position)
	#	var distance = get_distance(current_position, tile_position)
	#	if distance > movement:
	#		return
		if _astargrid.get_point_weight_scale(tile_position) > 999999:
	#	if _occupied_spaces.has(tile_position):
			var dir : Vector2i
			if current_position.x > tile_position.x:
				dir = Vector2i.RIGHT
			if current_position.y > tile_position.y:
				dir = Vector2i.DOWN
			if tile_position.x > current_position.x:
				dir = Vector2i.LEFT
			if tile_position.y > current_position.y:
				dir = Vector2i.UP
			tile_position += dir
		_path = _astargrid.get_point_path(current_position, tile_position)
		queue_redraw()
		return _path
#	print(_path)





func set_selected_skill(skill: String):
	_selected_skill = skill


func begin_target_selection():
	_skill_selected = true
	target_selection_started.emit()


func target_selected(target: Dictionary):
	combat.call(_selected_skill, controlled_combatant, target)
	_skill_selected = false
	target_selection_finished.emit()


const grid_tex = preload("res://imagese/grid_marker.png")

func get_tile_cost(tile, comb):
	var tile_data = tile_map.get_cell_tile_data(0, tile)
	if comb.movement_class == 0:
		return int(tile_data.get_custom_data("Cost"))
	else:
		return 1

func get_tile_cost_at_point(point, comb):
	var tile = tile_map.local_to_map(point)
	var tile_data = tile_map.get_cell_tile_data(0, tile)
	if comb.movement_class == 0:
		return int(tile_data.get_custom_data("Cost"))
	else:
		return 1

func _draw():
	for comb in combat.combatants:
		if comb.arrived == true and controlled_combatant == comb:
			var path_length = comb.movement_max
			for i in range(1, _path.size()):
				var point = _path[i]
				var draw_color = Color.RED
				if path_length > 0:
					if i <= comb.movement:
						draw_color = Color.ROYAL_BLUE
					draw_texture(grid_tex, point - Vector2(16, 16), draw_color)
				if i > 0:
					path_length -= get_tile_cost_at_point(point, comb)
				
			if _attack_target_position != null:
				draw_texture(grid_tex, _attack_target_position - Vector2(16, 16), Color.CRIMSON)
			if _blocked_target_position != null:
				draw_texture(grid_tex, _blocked_target_position - Vector2(16, 16))
		#elif comb.next_action_type == "Attack":
			#if _selected_skill
			
			
		elif comb.next_action_type != "None" and ((controlled_combatant_exists and comb != controlled_combatant) or (not controlled_combatant_exists)):
			if comb.next_action_type == "Move":
				if (not phase_ended) and comb.selected_path != PackedVector2Array():
					for i in range(1, comb.selected_path.size()):
						var point = comb.selected_path[i]
						var draw_color = Color.WHITE
						draw_texture(grid_tex, point - Vector2(16, 16), draw_color)
						#if i > 0:
							#path_length -= get_tile_cost_at_point(point, comb)
					
