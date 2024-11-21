extends Node2D
class_name CController
##Class for controlling sprites representing combatants on the tile map

signal movement_changed(movement: int)
signal finished_move
signal target_selection_started()
signal target_selection_finished()
signal combatant_selected(comb: Dictionary)
signal combatant_deselected()
signal signal_end_phase()
signal signal_end_turn()
signal combatant_lost_hp(comb: Dictionary)

var controlled_combatant_exists = false
@export var controlled_node: Node2D 
@export var combat: Combat
@export var controlled_combatant: Dictionary
@export var UI_node: Control

var tile_map : TileMapLayer
var obstacle_map : TileMapLayer
var phase_ended = false
var move_ended = false
var attack_ended = false
var spell_ended = false
var movement_astargrid = AStarGrid2D.new()
var movement_astargrid_region = Rect2i(-50, -50, 100, 100)
var sight_astargrid = AStarGrid2D.new()
var _mouse_target_position
#var _blocked_target_position
var _skill_selected = false
var _selected_skill: Object

var is_drawing_path = false #used to handle the custom path feature
var drawn_path = PackedVector2Array() #used to store the custom path





func _unhandled_input(event):	
	if event is InputEventKey and event.pressed:
		if Input.is_action_just_pressed("select_cancel"):
			controlled_combatant_exists = false
			controlled_combatant = {}
			combatant_deselected.emit()
			queue_redraw()
		elif Input.is_action_just_pressed("key_end_turn"):
			UI_node.end_phase.emit()
		else:
			for i in range(9):  # Handles keys 1 through 9 (and 0 as 10, optional)
				var action_name = "select_unit_" + str(i + 1)
				if Input.is_action_just_pressed(action_name):
					if i < combat.groups[0].size():
						var _comb_name = combat.groups[0][i]
						for comb in combat.combatants:
							if comb.name == _comb_name:
								set_controlled_combatant(comb)
								#now getting the mouse position to redras correctly the movement path (to not have to wait for the mouse the be moved)
								var mouse_position = get_global_mouse_position()
								var mouse_position_i = tile_map.local_to_map(mouse_position)
								find_path(mouse_position_i)
			
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.is_pressed():
				# Start drawing a custom path
				if controlled_combatant_exists and controlled_combatant.arrived:
					is_drawing_path = true
					drawn_path = PackedVector2Array()  # Reset the drawn path
			elif event.is_released():
				# Finish drawing the path
				if is_drawing_path and controlled_combatant_exists:
					is_drawing_path = false
					if is_path_valid(drawn_path):
						controlled_combatant.next_action_type = "Move"
						controlled_combatant.selected_path = drawn_path
						print("Custom path selected for ", controlled_combatant.name, " and it's : ", controlled_combatant.selected_path)
						controlled_combatant_exists = false
						controlled_combatant = {}
						combatant_deselected.emit()
						queue_redraw()
					else:
						print("Invalid custom path!")
						reset_selected_action(controlled_combatant)
						queue_redraw()
						
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_released():
				var mouse_position = get_global_mouse_position()
				var mouse_position_i = tile_map.local_to_map(mouse_position)
				var temp_path = find_path(mouse_position_i)
				var comb = {}
				
				if controlled_combatant == {}:
					comb = get_combatant_from_node((closest_node(check_mouse_over_sprites()))) #get_combatant_at_position(mouse_position_i)
				else:
					comb = get_combatant_at_position(mouse_position_i)
				var local_map = tile_map.map_to_local(mouse_position_i)
				if _skill_selected and controlled_combatant_exists and controlled_combatant.arrived:
					if is_target_valid(controlled_combatant, mouse_position_i):
						controlled_combatant.next_action_type = _selected_skill.type
						controlled_combatant.selected_targets.append(mouse_position_i)
						if controlled_combatant.selected_targets.size() >= _selected_skill.number_of_target:
							print("Target selected")
							target_selected(mouse_position_i)
					else:
						print("Target out of range !")
						reset_selected_action(controlled_combatant)
						_skill_selected = false
						_selected_skill = null
						target_selection_finished.emit()
						queue_redraw()
				elif controlled_combatant == {} and comb != null and comb.alive and comb.side == 0:
					set_controlled_combatant(comb)
				elif controlled_combatant_exists and controlled_combatant.arrived  :
					if not is_path_valid(temp_path):
						reset_selected_action(controlled_combatant)
						print("Action canceled for ", controlled_combatant.name)
						controlled_combatant_exists = false
						controlled_combatant = {}
						combatant_deselected.emit()
						queue_redraw()
					else:
						controlled_combatant.next_action_type = "Move"
						controlled_combatant.selected_path = temp_path
						print("New path selected for ", controlled_combatant.name)
						controlled_combatant_exists = false
						controlled_combatant = {}
						combatant_deselected.emit()
						queue_redraw()
	
	if event is InputEventMouseMotion:
		if is_drawing_path and controlled_combatant_exists:
			var mouse_position = get_global_mouse_position()
			var mouse_position_i = tile_map.local_to_map(mouse_position)
			# Add unique points to the drawn path
			if drawn_path == PackedVector2Array():
				drawn_path = find_path(mouse_position_i)
				print("hey : ", drawn_path)
				print(controlled_combatant.position)
			elif Vector2(mouse_position_i) != drawn_path[-1]:
				drawn_path.append(mouse_position_i)
		if _arrived == true:
			var mouse_position = get_global_mouse_position()
			var mouse_position_i = tile_map.local_to_map(mouse_position)
			find_path(mouse_position_i)
			var comb = get_combatant_at_position(mouse_position_i)
			var local_map = tile_map.map_to_local(mouse_position_i)
			if comb != null or movement_astargrid.get_point_weight_scale(mouse_position_i) > 99999:
				if comb == null or (comb.side == 1 and comb.alive):
					_mouse_target_position = local_map
				else:
					_mouse_target_position = null
					#_blocked_target_position = local_map
			else:
				_mouse_target_position = null
			#elif controlled_combatant_exists and mouse_position_i in _blocking_spaces[controlled_combatant.movement_class]:
			#	_blocked_target_position = local_map
			#else:
			#	_mouse_target_position = null
			#	_blocked_target_position = null
func get_combatant_from_node(target_node: Node2D):
	if target_node != null:
		for comb in combat.combatants:
			if comb.name == target_node.name and comb.alive:
				return comb
	return null

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
func closest_node(array: Array):
	var res = null
	if array != []:
		res = array[-1]
	return res

func get_bounding_box_for_sprites2(node: Node2D) -> Rect2:
	var global_rect = Rect2()  # Initialize the global rectangle
	var first_sprite = true
	for child in node.get_children():
		if child is Sprite2D:
			var texture_size = child.texture.get_size() * child.scale
			var sprite_top_left = child.global_position - Vector2(texture_size.x/2, texture_size.y)
			var sprite_rect = Rect2(sprite_top_left, texture_size)
			if first_sprite:
				global_rect = sprite_rect  # Initialize the global rect with the first sprite
				first_sprite = false
			else:
				global_rect = global_rect.merge(sprite_rect)  # Merge with the existing bounding box
	return global_rect


# Function to check if the mouse is over a Node2D based on its Sprite2D children
func is_mouse_over_sprite(node: Node2D) -> bool:
	var mouse_position = get_global_mouse_position()
	var bounding_box = get_bounding_box_for_sprites2(node)
	var box_position = bounding_box["position"]
	var box_size = bounding_box["size"]
	return mouse_position.x >= box_position.x and mouse_position.x <= box_position.x + box_size.x and \
		   mouse_position.y >= box_position.y and mouse_position.y <= box_position.y + box_size.y

# Function to iterate over children of the "combat" node and check if the mouse is over any Node2D
func check_mouse_over_sprites():
	var _concerned_nodes = []
	for node in combat.get_children():
		if node is Node2D and is_mouse_over_sprite(node):
			print("Mouse is over sprite: ", node.name)
			_concerned_nodes.append(node)
	return _concerned_nodes

func is_path_valid(path):
	# Ensure the path is valid (e.g., within movement range, not blocked)
	if path == PackedVector2Array() or path.size() - 1 > controlled_combatant.movement:
		return false
	var _previous_point = path[0]
	for point in path:
		if movement_astargrid.get_point_weight_scale(point) > 99999:
			return false
		elif (_previous_point - point).length() > 1:
			return false
		_previous_point = point
	return true



func _ready():
	tile_map = get_node("../Terrain/TileMapLayer")
	obstacle_map = get_node("../Terrain/WallMapLayer")
	movement_astargrid.region = movement_astargrid_region
	movement_astargrid.cell_size = Vector2i(1, 1)
	movement_astargrid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	movement_astargrid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	movement_astargrid.update()
	# Define the function to update weights from obstacles
	update_tile_weights_from_obstacles()
	
	sight_astargrid.region = Rect2i(-50, -50, 100, 100)
	sight_astargrid.cell_size = Vector2i(1, 1)
	sight_astargrid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	sight_astargrid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	sight_astargrid.update()
	
	
	#build blocking spaces arrays
	for tile in tile_map.get_used_cells():
		var tile_blocking = tile_map.get_cell_tile_data(tile)
		for block in tile_blocking.get_custom_data("Blocks"):
			_blocking_spaces[block].append(tile)	
	
func combat_start():
	combat.phase = 3
	new_phase_init()

func new_phase_init():
	if combat.phase == 3:
		print("New turn !")
		end_turn()
		combat.phase = 1
	else:
		combat.phase += 1
	print("Phase ", combat.phase)
	controlled_combatant_exists = false
	for comb in combat.combatants:
		comb.next_action_type = "None"
		comb.next_move = []
		comb.selected_path = []
	queue_redraw()
	signal_end_phase.emit()

func combatant_added(combatant):
#	movement_astargrid.set_point_solid(combatant.position, true)
#	movement_astargrid.set_point_weight_scale(combatant.position, INF)
	_occupied_spaces.append(combatant.position)


func combatant_died(combatant):
#	movement_astargrid.set_point_solid(combatant.position, false)
	#movement_astargrid.set_point_weight_scale(combatant.position, 1)
	_occupied_spaces.erase(combatant.position)


func set_controlled_combatant(combatant: Dictionary):
	var movement = combatant.movement
	controlled_combatant = combatant
	controlled_combatant_exists = true
	reset_selected_action(controlled_combatant)
	_skill_selected = false
	_selected_skill = null
	print("Controlled_combatant set : ", controlled_combatant.name)
	combatant_selected.emit(controlled_combatant)
	update_points_weight(combatant)

func update_points_weight(comb: Dictionary):
	pass
	#Update occupied spaces for flying units
	#for point in _occupied_spaces:
		#if comb.movement_class == 1:
			#_astargrid.set_point_weight_scale(point, 1)
		#else:
			#_astargrid.set_point_weight_scale(point, INF)
	#Update point weights for blocking spaces
	#for class_m in range(_blocking_spaces.size()):
		#for space in _blocking_spaces[class_m]:
			#if controlled_combatant.movement_class == class_m:
			#	_astargrid.set_point_weight_scale(space, INF)
			#else:
			#	_astargrid.set_point_weight_scale(space, 1)

func get_distance(point1: Vector2i, point2: Vector2i):
	return absi(point1.x - point2.x) + absi(point1.y - point2.y)


var _arrived = true

var _path : PackedVector2Array

var _next_position

var _position_id = 0

var move_speed = 300

var _previous_position : Vector2i

func _process(delta):
	for comb in combat.combatants:
		if comb.arrived == false:
			var _comb_visual_node = get_node("/root/Game/Terrain/VisualCombat/" + comb.name)
			_comb_visual_node.position += _comb_visual_node.position.direction_to(tile_map.map_to_local(comb.position) + comb.sprite_offset) * delta * comb.move_speed
			if _comb_visual_node.position.distance_to(tile_map.map_to_local(comb.position) + comb.sprite_offset) < 5 :
				if comb.selected_path_id >= comb.selected_path.size() or comb.movement <= 0:
					compute_finish_move(comb, _comb_visual_node)
				else:
					var new_position = comb.selected_path[comb.selected_path_id]
					_next_position = tile_map.map_to_local(new_position)
					var _next_position_comb = get_combatant_at_position(new_position)
					var next_tile_cost = get_tile_cost(new_position, comb)
					if next_tile_cost <= comb.movement and (_next_position_comb == null or (_next_position_comb.is_transparent and not _next_position_comb.arrived)):
						comb.position = tile_map.local_to_map(_next_position)
						comb.selected_path_id += 1
						comb.movement -= next_tile_cost
						print("-1 de mov")
					else:
						compute_finish_move(comb, _comb_visual_node)

				
	if phase_ended: 
		if verifying_arrived() and verifying_moved() and verifying_attacked() and verifying_spelled() :
			phase_ended = false
			move_ended = false
			attack_ended = false
			spell_ended = false
			new_phase_init()
		elif verifying_arrived() and verifying_moved() and verifying_attacked():
			end_phase()
		elif verifying_arrived() and verifying_moved():
			end_phase()

func compute_finish_move(comb: Dictionary, _comb_visual_node):
	finished_move.emit()
	comb.arrived = true
	reset_selected_action(comb)
	_comb_visual_node.position = tile_map.map_to_local(comb.position) + comb.sprite_offset
	print("fin de movement!")

func verifying_arrived():
	var _verifying_arrived = true
	for comb in combat.combatants:
		if not comb.arrived:
			_verifying_arrived = false
	return _verifying_arrived

func verifying_moved():
	var _verifying_moved = true
	for comb in combat.combatants:
		if comb.next_action_type == "Move":
			_verifying_moved = false
	return _verifying_moved

func verifying_attacked():
	var _verifying_attacked = true
	for comb in combat.combatants:
		if comb.next_action_type == "Attack":
			_verifying_attacked = false
	return _verifying_attacked
	
func verifying_spelled():
	var _verifying_spelled = true
	for comb in combat.combatants:
		if comb.next_action_type == "Spell":
			_verifying_spelled = false
	return _verifying_spelled

func get_main_vec_comp(position1, position2):
	var _diff = position2 - position1
	if _diff == Vector2i(0,0):
		return "0"
	elif abs(_diff.x) > abs(_diff.y):
		return "x"
	elif abs(_diff.x) < abs(_diff.y):
		return "y"
	else:
		return "="

func get_vec_dir(position1, position2):
	var _diff = position2 - position1
	if _diff.x == 0 and _diff.y == 0:
		return "self"
	elif _diff.x == 0 and _diff.y >= 0:
		return "top"
	elif _diff.x == 0 and _diff.y <= 0:
		return "bottom"
	elif _diff.x >= 0 and _diff.y == 0:
		return "right"
	elif _diff.x <= 0 and _diff.y == 0:
		return "left"
	elif _diff.x >= 0 and _diff.y >= 0:
		return "bottom_right"
	elif _diff.x <= 0 and _diff.y >= 0:
		return "bottom_left"
	elif _diff.x >= 0 and _diff.y <= 0:
		return "top_right"
	elif _diff.x <= 0 and _diff.y <= 0:
		return "top_left"
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
		controlled_combatant = {}
		combatant_deselected.emit()
		for comb in combat.combatants:
			if comb.next_action_type == "Move":
				print(comb.name, " has type Move")
				move_combatant(comb)
			elif comb.next_action_type == "Attack" and verifying_moved():
				if combat.phase == 1:
					print("ERREUR : No Attack Allowed Phase 1")
				else:
					print(comb.name, " has type Attack")
					attack_combatant(comb)
			elif comb.next_action_type == "Spell" and verifying_attacked():
				if combat.phase == 2:
					print(comb.name, " has type Spell")
					spell_combatant(comb)
				else:
					print("ERREUR : No Spell allowed in Phase 1 or Phase 3")
		phase_ended = true	
		queue_redraw()

func end_turn():
	for comb in combat.combatants: 
		comb.movement = comb.movement_max
		comb.number_attacks = comb.number_attacks_max
		for status in comb.statuses:
			print(comb.name, " has ", status.name)
			if status.turn_to_go <= 0:
				if status.time == 0:
					comb[status.stat] -= status.effect
				(comb.statuses).erase(status)
				print("end of effect !")
			elif status.delay <= 0:
				if status.time == 1:
					comb[status.stat] += status.effect
				elif status.turn_to_go == status.turn_total:
					comb[status.stat] += status.effect
					print("effect starts ! ", comb.name, " now has ", comb[status.stat])
				status.turn_to_go -= 1
			else:
				status.delay -= 1
				print("effect in casting time")
	combat.turn += 1
	print("turn ", combat.turn)

func move_combatant(comb: Dictionary):
	var _path_size = comb.selected_path.size()
	if _path_size > 1 and comb.movement > 0:
		comb.previous_position = comb.position
		comb.selected_path_id = 1
		comb.arrived = false
		print(comb.name, " bouge de ", comb.movement," sur le chemin : ", comb.selected_path)
		queue_redraw()
	

func attack_combatant(comb: Dictionary):
	var _skill_used = SkillDatabase.skills[(comb.selected_skill_id)]
	for _tile in comb.selected_targets:
		var targeted_comb = get_combatant_at_position(_tile)
		if targeted_comb == null:
			print(comb.name, " hits ", _tile, " but it's empty")
		else:
			print(comb.name, " tries to attack ", targeted_comb.name)
			attack_compute(comb, targeted_comb)
		for _suppl_offset in _skill_used.hit_zone:
			var _new_tile = hit_zone_compute(comb, _tile, _suppl_offset)
			targeted_comb = get_combatant_at_position(_new_tile)
			if targeted_comb == null:
				print(comb.name, " hits ", _tile+_suppl_offset, " but it's empty")
			else:
				print(comb.name, " tries to attack ", targeted_comb.name)
				attack_compute(comb, targeted_comb)
	comb.number_attacks -= 1
	reset_selected_action(comb)
	
func spell_combatant(comb: Dictionary):
	var _skill_used = SkillDatabase.skills[(comb.selected_skill_id)]
	for _tile in comb.selected_targets:
		var targeted_comb = get_combatant_at_position(_tile)
		if targeted_comb == null:
			print(comb.name, " does magic at ", _tile, " but it's empty")
		else:
			print(comb.name, " tries to spellzzz ", targeted_comb.name)
			spell_compute(comb, targeted_comb)
		for _suppl_offset in _skill_used.hit_zone:
			var _new_tile = hit_zone_compute(comb, _tile, _suppl_offset)
			targeted_comb = get_combatant_at_position(_new_tile)
			if targeted_comb == null:
				print(comb.name, " does magic at ", _tile+_suppl_offset, " but it's empty")
			else:
				print(comb.name, " tries to spellzzz ", targeted_comb.name)
				spell_compute(comb, targeted_comb)
	reset_selected_action(comb)

func hit_zone_compute(comb, _tile, _suppl_offset):
	var _new_tile: Vector2i
	var _dir = get_main_vec_comp(comb.position, _tile)
	if _dir == "0":
		_new_tile = _tile + _suppl_offset
	elif  _dir == "x":
		_new_tile = _tile + Vector2i(_suppl_offset.y, _suppl_offset.x)
	elif _dir == "y":
		_new_tile = _tile + _suppl_offset
	else:
		if get_vec_dir(comb.position, _tile) == "bottom_right" or get_vec_dir(comb.position, _tile) == "top_left":
			_new_tile.x = _tile.x - _suppl_offset.x + _suppl_offset.y
			_new_tile.y = _tile.y + _suppl_offset.x + _suppl_offset.y
		else:
			_new_tile.x = _tile.x + _suppl_offset.x - _suppl_offset.y
			_new_tile.y = _tile.y + _suppl_offset.x + _suppl_offset.y
	return _new_tile

func attack_compute(comb, targeted_comb):
	var _skill_used = SkillDatabase.skills[(comb.selected_skill_id)]
	var _prob = randf_range(0.0, 1.0)
	if _prob < _skill_used.prob:
		var _hp_loss = (comb.strength * _skill_used.damage)/targeted_comb.toughness
		var _prob_crit = randi_range(0, 100)
		if _prob_crit < comb.crit_chance:
			print("!!!CRIT!!!")
			_hp_loss = int(_hp_loss * 1.5)
		_hp_loss -= _skill_used.armor_penetration
		_hp_loss += targeted_comb.armor_save
		targeted_comb.hp -= _hp_loss
		combatant_lost_hp.emit(targeted_comb)
		if targeted_comb.hp <= 0:
			targeted_comb.hp = 0
			comb_died(targeted_comb)
		print(targeted_comb.name, " lost ", _hp_loss, " and now has ", targeted_comb.hp, " hp.")
	else:
		print("attack failed")
		
func spell_compute(comb, targeted_comb):
	var _skill_used = SkillDatabase.skills[(comb.selected_skill_id)]
	var _prob = randf_range(0.0, 1.0)
	if _prob < _skill_used.prob:
		if _skill_used.damage != 0:
			var _hp_loss = (comb.psy_power * _skill_used.damage)/targeted_comb.toughness
			targeted_comb.hp -= _hp_loss
			combatant_lost_hp.emit(targeted_comb)
			print(targeted_comb.name, " lost ", _hp_loss, " and now has ", targeted_comb.hp, " hp.")
		if targeted_comb.hp <= 0:
			targeted_comb.hp = 0
			comb_died(targeted_comb)
		for status in _skill_used.statuses:
			status.turn_to_go = status.turn_total
			var status_copy = status.duplicate(true)
			(targeted_comb.statuses).append(status_copy)
			print(targeted_comb.name, " has now status ", status_copy.name)
	else:
		print("spell failed")
	_skill_used.end_cd_turn = combat.turn + _skill_used.cd
	print(_skill_used.name, " can be used next in turn ", _skill_used.end_cd_turn)
		
func comb_died(comb: Dictionary):
	print(comb.name, " died AH LOOSER!")
	get_node("/root/Game/Terrain/VisualCombat/" + comb.name).queue_free()
	var	comb_id = combat.combatants.find(comb)
	if comb_id != -1:
		combat.combatants.pop_at(comb_id)
		combat.groups[comb.side].erase(comb_id)
		combat.current_combatant_alive -= 1

#func ai_move(target_position: Vector2i):
#	var current_position = tile_map.local_to_map(controlled_node.position)
#	find_path(target_position)
#	print(target_position)
#	move_on_path(current_position)

# Define the function to update weights from obstacles
func update_tile_weights_from_obstacles():  # Reference to your ObstaclesTileMap
	for tile_pos in obstacle_map.get_used_cells():
		movement_astargrid.set_point_weight_scale(tile_pos, 999999)  # Impassable weight


func find_path(tile_position: Vector2i):
	if controlled_combatant_exists:
		var current_position = controlled_combatant.position
		if movement_astargrid.get_point_weight_scale(tile_position) > 99999 and (get_combatant_at_position(tile_position) == null):
			var dir : Vector2i
			if current_position.x > tile_position.x:
				dir = Vector2i.RIGHT
			if tile_position.x > current_position.x:
				dir = Vector2i.LEFT
			if current_position.y > tile_position.y:
				dir = Vector2i.DOWN
			if tile_position.y > current_position.y:
				dir = Vector2i.UP
			tile_position += dir
		_path = movement_astargrid.get_point_path(current_position, tile_position)
		queue_redraw()
		return _path

func compute_sight(position1: Vector2i, position2: Vector2i) -> bool:
	# Bresenham's line algorithm for 2D grids
	var x0 = position1.x
	var y0 = position1.y
	var x1 = position2.x
	var y1 = position2.y
	var dx = abs(x1 - x0)
	var dy = abs(y1 - y0)
	var sx = 1
	if x0 > x1:
		sx = -1
	var sy = 1
	if y0 > y1:
		sy = -1
	var err = dx - dy
	while true:
		# Check if the cell is occupied
		if obstacle_map.get_cell_source_id(Vector2i(x0,y0)) != -1:  # Adjust for your specific layer settings
			var cell_data = obstacle_map.get_cell_tile_data(Vector2i(x0, y0))
			if cell_data == null or not cell_data.get_custom_data("see_throught"):
				return false # An occupied cell is in the way
		# Break if we've reached the end cell
		if x0 == x1 and y0 == y1:
			break
		# Move to the next cell
		var e2 = 2 * err
		if e2 > -dy:
			err -= dy
			x0 += sx
		if e2 < dx:
			err += dx
			y0 += sy
	return true  # No occupied cells in the way


func reset_selected_action(combatant: Dictionary):
	combatant.selected_path_id = 1
	combatant.selected_path = []
	combatant.selected_skill_id = null
	combatant.selected_targets = []
	combatant.next_action_type = "None"



func set_selected_skill(skill_key: String):
	_selected_skill = SkillDatabase.skills[skill_key]
	controlled_combatant.selected_skill_id = skill_key


func begin_target_selection():
	_skill_selected = true
	target_selection_started.emit()
	queue_redraw()

func is_target_valid(comb: Dictionary, mouse_pos_i):
	if _selected_skill.range_type == "Range":
		return is_in_range(comb.position, mouse_pos_i, _selected_skill.min_range, _selected_skill.max_range, _selected_skill.sight)
	elif _selected_skill.range_type == "List":
		return is_in_list(comb.position, mouse_pos_i, _selected_skill.range_list)
	#check if the coord match the allowed coordinates for that given skill

func is_in_range(position1, position2, min_range, max_range, sight: bool):
	return (get_distance(position1, position2) >= min_range and get_distance(position1, position2) <= max_range and compute_sight(position1, position2))

func is_in_list(position1: Vector2i, position2: Vector2i, range_list):
	return (position2 - position1) in range_list

func target_selected(target_position):
	#combat.call(_selected_skill.type, controlled_combatant, target)
	_skill_selected = false
	_selected_skill = null
	controlled_combatant = {}
	controlled_combatant_exists = false
	target_selection_finished.emit()
	combatant_deselected.emit()


const grid_tex = preload("res://imagese/grid_marker.png")

func get_tile_cost(tile, comb):
	if comb.movement_class != "fly":
		for obstacle_tile in obstacle_map.get_used_cells():
			if (Vector2i(tile) == obstacle_tile):
				var res = 999999
				return res
		var tile_data = tile_map.get_cell_tile_data(tile)
		#return tile_data.get_custom_data("Cost") as int
		return 1
	else:
		return 1

func get_tile_cost_at_point(point, comb):
	var tile = tile_map.local_to_map(point)
	return get_tile_cost(tile, comb)

func _draw():
	if is_drawing_path and drawn_path.size() > 0:
		# Draw the path as a series of connected lines
		var last_position = tile_map.map_to_local(controlled_combatant.position)  # Start at the combatant's position
		for i in range(drawn_path.size()):
			if i <= controlled_combatant.movement:
				var local_position = tile_map.map_to_local(drawn_path[i])
				draw_line(last_position, local_position, Color(0, 0.8, 0, 0.7), 2)
				last_position = local_position
			elif i == controlled_combatant.movement+1:
				var local_position = tile_map.map_to_local(drawn_path[i])
				draw_line(last_position, local_position, Color(0.5, 0, 0, 1), 2)
				last_position = local_position
	for child in combat.get_children():
		# Calculate the bounding box for sprites in combat
		var bounding_box = get_bounding_box_for_sprites2(child)

		# Draw the bounding box
		draw_rect(bounding_box, Color(1, 0, 0, 0.5), false)  # Red rectangle with 50% opacity
		
	for comb in combat.combatants:
		if comb.arrived and _skill_selected == false and controlled_combatant == comb and comb.next_action_type == "None" and not is_drawing_path:
			var path_length = comb.movement_max
			for i in range(1, _path.size()):
				var point = tile_map.map_to_local(_path[i])
				var draw_color = Color(0.7,0,0,0.5)
				if path_length > 0:
					if i <= comb.movement and movement_astargrid.get_point_weight_scale(_path[i]) < 1000:
						draw_color = Color(0, 1, 0.2, 0.5)
					draw_texture(grid_tex, point - Vector2(32, 16), draw_color)
				if i > 0:
					path_length -= get_tile_cost_at_point(point, comb)
			if _mouse_target_position != null:
				draw_texture(grid_tex, _mouse_target_position - Vector2(32, 16), Color(0.7,0,0,0.5))
			#if _blocked_target_position != null:
				#draw_texture(grid_tex, _blocked_target_position - Vector2(32, 22))
		#elif comb.next_action_type == "Attack":
			#if _selected_skill
			
		elif comb.arrived and _skill_selected and controlled_combatant == comb:
			var mouse_position = get_global_mouse_position()
			var mouse_position_i = tile_map.local_to_map(mouse_position)
			draw_texture(grid_tex, tile_map.map_to_local(mouse_position_i) - Vector2(32, 16), Color(0, 1, 1, 0.9))
			var _skill_used = SkillDatabase.skills[(comb.selected_skill_id)]
			if is_in_range(comb.position, mouse_position_i, _selected_skill.min_range, _selected_skill.max_range, _selected_skill.sight):
				for _suppl_offset in _skill_used.hit_zone:
					var _new_tile = hit_zone_compute(comb, mouse_position_i, _suppl_offset)
					draw_texture(grid_tex, tile_map.map_to_local(_new_tile) - Vector2(32, 16), Color(0, 1, 1, 0.9))
			if _selected_skill.range_type == "Range":
				for x in range(-(_selected_skill.max_range+1), _selected_skill.max_range+1):
					for y in range(-(_selected_skill.max_range+1), _selected_skill.max_range+1):
						var _tile = comb.position + Vector2i(x,y)
						if is_in_range(comb.position, _tile, _selected_skill.min_range, _selected_skill.max_range, _selected_skill.sight):
							draw_texture(grid_tex, tile_map.map_to_local(_tile) - Vector2(32, 16), Color(0, 0.5, 0.5, 0.4))
				for target in comb.selected_targets:
					draw_texture(grid_tex, tile_map.map_to_local(target) - Vector2(32, 16), Color(0, 0.5, 0.5, 0.8))
					#var _skill_used = SkillDatabase.skills[(comb.selected_skill_id)]
					for _suppl_offset in _skill_used.hit_zone:
						var _new_tile = hit_zone_compute(comb, target, _suppl_offset)
						draw_texture(grid_tex, tile_map.map_to_local(_new_tile) - Vector2(32, 16), Color(0, 0.5, 0.5, 0.6))
				#for tile in _selected_skill.
		if comb.next_action_type != "None" and ((controlled_combatant_exists and comb != controlled_combatant) or (not controlled_combatant_exists)):
			if comb.next_action_type == "Move":
				if (not phase_ended) and comb.selected_path != PackedVector2Array():
					for i in range(1, comb.selected_path.size()):
						var point = tile_map.map_to_local(comb.selected_path[i])
						var draw_color = Color(0, 0.5, 0, 0.5)
						draw_texture(grid_tex, point - Vector2(32, 16), draw_color)
						#if i > 0:
							#path_length -= get_tile_cost_at_point(point, comb)
			elif comb.next_action_type == "Attack" or "Spell":
				if (not phase_ended):
					for target in comb.selected_targets:
						draw_texture(grid_tex, tile_map.map_to_local(target) - Vector2(32, 16), Color(0, 0.5, 1, 0.6))
						var _skill_used = SkillDatabase.skills[(comb.selected_skill_id)]
						for _suppl_offset in _skill_used.hit_zone:
							var _new_tile = hit_zone_compute(comb, target, _suppl_offset)
							draw_texture(grid_tex, tile_map.map_to_local(_new_tile) - Vector2(32, 16), Color(0, 0.5, 1, 0.6))
