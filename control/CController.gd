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
var tile_map : TileMapLayer
var phase_ended = false
var _astargrid = AStarGrid2D.new()
var _attack_target_position
var _blocked_target_position
var _skill_selected = false
var _selected_skill: Object

func _unhandled_input(event):	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_released():
				var mouse_position = get_global_mouse_position()
				var mouse_position_i = tile_map.local_to_map(mouse_position)
				var temp_path = find_path(mouse_position_i)
				var comb = get_combatant_at_position(mouse_position_i)
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
				elif comb != null and comb.alive and comb.side == 0:
					set_controlled_combatant(comb)
				elif comb == null and controlled_combatant_exists and controlled_combatant.arrived :
					if temp_path.size() - 1 > controlled_combatant.movement:
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
	tile_map = get_node("../Terrain/TileMapLayer")
	_astargrid.region = Rect2i(0, -20, 36, 36)
	_astargrid.cell_size = Vector2i(1, 1)
	#_astargrid.offset = Vector2(32, 16)
	_astargrid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_astargrid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_astargrid.update()
	
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
	signal_end_phase.emit()

func combatant_added(combatant):
#	_astargrid.set_point_solid(combatant.position, true)
#	_astargrid.set_point_weight_scale(combatant.position, INF)
	_occupied_spaces.append(combatant.position)


func combatant_died(combatant):
#	_astargrid.set_point_solid(combatant.position, false)
	_astargrid.set_point_weight_scale(combatant.position, 1)
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

var move_speed = 300

var _previous_position : Vector2i

func _process(delta):
	for comb in combat.combatants:
		if comb.arrived == false:
			var new_position: Vector2i = comb.selected_path[comb.selected_path_id]
			_next_position = tile_map.map_to_local(new_position) + comb.sprite_offset
			var _next_position_comb = get_combatant_at_position(new_position)
			#verifying that, if two characters are about to bump into each other, they are not going in opposite directions. 
			if (_next_position_comb == null): #or (_next_position_comb.arrived == false and _next_position_comb.sprite.position.direction_to(_next_position_comb.selected_path[_next_position_comb.selected_path_id]) != -1*comb.sprite.position.direction_to(_next_position))):
				var _comb_visual_node = get_node("/root/Game/VisualCombat/" + comb.name)
				_comb_visual_node.position += _comb_visual_node.position.direction_to(_next_position) * delta * move_speed
				if _comb_visual_node.position.distance_to(_next_position) < 1 :
		#			_astargrid.set_point_solid(_previous_position, false)
					print(comb.name, " at position ", comb.position, " goes to ", new_position, " occupied by ", get_combatant_at_position(_next_position))
					_occupied_spaces.erase(comb.previous_position)
					_astargrid.set_point_weight_scale(comb.previous_position, 1)
					var tile_cost = get_tile_cost(comb.previous_position, comb)
					_comb_visual_node.position = _next_position
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
						reset_selected_action(comb)
			else:
				comb.arrived = true
				reset_selected_action(comb)
				
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
			elif comb.next_action_type == "Attack":
				if combat.phase == 1:
					print("ERREUR : No Attack Allowed Phase 1")
				else:
					print(comb.name, " has type Attack")
					attack_combatant(comb)
			elif comb.next_action_type == "Spell":
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
			print(comb.statuses)
			if status.turn_to_go <= 0:
				if status.time == 0:
					comb[status.stat] -= status.effect
				(comb.statuses).erase(status)
				print("fin d'effet !")
			elif status.delay <= 0:
				if status.time == 1:
					comb[status.stat] += status.effect
				elif status.turn_to_go == status.turn_total:
					comb[status.stat] += status.effect
					print("début d'effet ! ", comb.name, " now has ", comb[status.stat])
				status.turn_to_go -= 1
			else:
				status.delay -= 1
				print("effet en delay")
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
	get_node("/root/Game/VisualCombat/" + comb.name).queue_free()
	var	comb_id = combat.combatants.find(comb)
	if comb_id != -1:
		combat.groups[comb.side].erase(comb_id)
		combat.current_combatant_alive -= 1

#func ai_move(target_position: Vector2i):
#	var current_position = tile_map.local_to_map(controlled_node.position)
#	find_path(target_position)
#	print(target_position)
#	move_on_path(current_position)


func find_path(tile_position: Vector2i):
	if controlled_combatant_exists:
		var current_position = controlled_combatant.position
		if _astargrid.get_point_weight_scale(tile_position) > 999999:
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
		return is_in_range(comb.position, mouse_pos_i, _selected_skill.min_range, _selected_skill.max_range)
	elif _selected_skill.range_type == "List":
		return is_in_list(comb.position, mouse_pos_i, _selected_skill.range_list)
	#check if the coord match the allowed coordinates for that given skill

func is_in_range(position1, position2, min_range, max_range):
	return (get_distance(position1, position2) >= min_range and get_distance(position1, position2) <= max_range)

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
	var tile_data = tile_map.get_cell_tile_data(tile)
	if comb.movement_class == 0:
		return int(tile_data.get_custom_data("Cost"))
	else:
		return 1

func get_tile_cost_at_point(point, comb):
	var tile = tile_map.local_to_map(point)
	var tile_data = tile_map.get_cell_tile_data(tile)
	if comb.movement_class == 0:
		return int(tile_data.get_custom_data("Cost"))
	else:
		return 1

func _draw():
	for comb in combat.combatants:
		if comb.arrived and _skill_selected == false and controlled_combatant == comb and comb.next_action_type == "None":
			var path_length = comb.movement_max
			for i in range(1, _path.size()):
				var point = tile_map.map_to_local(_path[i])
				var draw_color = Color(0.7,0,0,0.5)
				if path_length > 0:
					if i <= comb.movement:
						draw_color = Color(0, 1, 0.2, 0.5)
					draw_texture(grid_tex, point - Vector2(32, 22), draw_color)
				if i > 0:
					path_length -= get_tile_cost_at_point(point, comb)
			if _attack_target_position != null:
				draw_texture(grid_tex, _attack_target_position - Vector2(32, 22), Color.CRIMSON)
			if _blocked_target_position != null:
				draw_texture(grid_tex, _blocked_target_position - Vector2(32, 22))
		#elif comb.next_action_type == "Attack":
			#if _selected_skill
			
		elif comb.arrived and _skill_selected and controlled_combatant == comb:
			var mouse_position = get_global_mouse_position()
			var mouse_position_i = tile_map.local_to_map(mouse_position)
			draw_texture(grid_tex, tile_map.map_to_local(mouse_position_i) - Vector2(32, 22), Color(0, 1, 1, 0.9))
			var _skill_used = SkillDatabase.skills[(comb.selected_skill_id)]
			if is_in_range(comb.position, mouse_position_i, _selected_skill.min_range, _selected_skill.max_range):
				for _suppl_offset in _skill_used.hit_zone:
					var _new_tile = hit_zone_compute(comb, mouse_position_i, _suppl_offset)
					draw_texture(grid_tex, tile_map.map_to_local(_new_tile) - Vector2(32, 22), Color(0, 1, 1, 0.9))
			if _selected_skill.range_type == "Range":
				for x in range(-(_selected_skill.max_range+1), _selected_skill.max_range+1):
					for y in range(-(_selected_skill.max_range+1), _selected_skill.max_range+1):
						var _tile = comb.position + Vector2i(x,y)
						if is_in_range(comb.position, _tile, _selected_skill.min_range, _selected_skill.max_range):
							draw_texture(grid_tex, tile_map.map_to_local(_tile) - Vector2(32, 22), Color(0, 0.5, 0.5, 0.4))
				for target in comb.selected_targets:
					draw_texture(grid_tex, tile_map.map_to_local(target) - Vector2(32, 22), Color(0, 0.5, 0.5, 0.8))
					#var _skill_used = SkillDatabase.skills[(comb.selected_skill_id)]
					for _suppl_offset in _skill_used.hit_zone:
						var _new_tile = hit_zone_compute(comb, target, _suppl_offset)
						draw_texture(grid_tex, tile_map.map_to_local(_new_tile) - Vector2(32, 22), Color(0, 0.5, 0.5, 0.6))
				#for tile in _selected_skill.
		if comb.next_action_type != "None" and ((controlled_combatant_exists and comb != controlled_combatant) or (not controlled_combatant_exists)):
			if comb.next_action_type == "Move":
				if (not phase_ended) and comb.selected_path != PackedVector2Array():
					for i in range(1, comb.selected_path.size()):
						var point = tile_map.map_to_local(comb.selected_path[i])
						var draw_color = Color(0, 0.5, 0, 0.5)
						draw_texture(grid_tex, point - Vector2(32, 22), draw_color)
						#if i > 0:
							#path_length -= get_tile_cost_at_point(point, comb)
			elif comb.next_action_type == "Attack" or "Spell":
				if (not phase_ended):
					for target in comb.selected_targets:
						draw_texture(grid_tex, tile_map.map_to_local(target) - Vector2(32, 22), Color(0, 0.5, 1, 0.6))
						var _skill_used = SkillDatabase.skills[(comb.selected_skill_id)]
						for _suppl_offset in _skill_used.hit_zone:
							var _new_tile = hit_zone_compute(comb, target, _suppl_offset)
							draw_texture(grid_tex, tile_map.map_to_local(_new_tile) - Vector2(32, 22), Color(0, 0.5, 1, 0.6))
