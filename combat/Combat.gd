extends Node
class_name Combat

signal register_combat(combat_node: Node)
signal turn_advanced(combatant: Dictionary)
signal combatant_added(combatant: Dictionary)
signal combatant_died(combatant: Dictionary)
signal update_turn_queue(combatants: Array, turn_queue: Array)
signal update_information(text: String)
signal update_combatants(combatants: Array)
signal combat_finished()
signal combat_start()
signal new_turn(combatants: Array)
signal end_turn(combatants: Array)

var combatants = []
var phase = 3
var turn = 0
var temporary_obstacles = []
var temporary_units = []
var temporary_traps = [] #called it "temporary" just to have the same names as above

enum Group
{
	PLAYERS,
	ENEMIES
}

enum UnitClass
{
	Melee,
	Ranged,
	Magic
}

var groups = [
	[], #players
	[]  #enemies
]

var current_combatant = 0
var current_combatant_alive = 0

@export var game_ui : Control
@export var controller : CController


var army_list = [
	"Ultramarine",
	"Black_Legion",
	"Tyranid"
]
var skills_lists = [
	["attack_melee"], #Melee
	["attack_melee", "attack_ranged"], #Ranged
	["attack_melee", "attack_ranged", "basic_magic"] #Ranged + Magic
]

@onready var tile_map = get_node("../TileMapLayer")

func _ready():
	emit_signal("register_combat", self)
	randomize()
	#ADD PLAYERS
	add_combatant(create_combatant(CombatantDatabase.combatants["ultramarine_intercessor_boltgun"], "Space_Marine_1"), 0, Vector2i(10,0))
	#add_combatant(create_combatant(CombatantDatabase.combatants["ultramarine_intercessor_boltpistol_chainsword"], "Space_Marine_2"), 0, Vector2i(9,-3))
	#add_combatant(create_combatant(CombatantDatabase.combatants["ultramarine_intercessor_boltpistol_chainsword"], "Space_Marine_3"), 0, Vector2i(9,2))
	
	
	
	#ADD ENEMIES
	
	#add_combatant(create_combatant(CombatantDatabase.combatants["tyranids_lictor"], "Tyranid_1"), 1, Vector2i(24,3))
	#add_combatant(create_combatant(CombatantDatabase.combatants["tyranids_hormagaunt"], "Tyranid_2"), 1, Vector2i(25,-4))
	#add_combatant(create_combatant(CombatantDatabase.combatants["tyranids_hormagaunt"], "Tyranid_3"), 1, Vector2i(23,-8))
	#add_combatant(create_combatant(CombatantDatabase.combatants["tyranids_hormagaunt"], "Tyranid_4"), 1, Vector2i(27,-6))
	#add_combatant(create_combatant(CombatantDatabase.combatants["tyranids_hormagaunt"], "Tyranid_5"), 1, Vector2i(28,8))
	#add_combatant(create_combatant(CombatantDatabase.combatants["tyranids_hormagaunt"], "Tyranid_6"), 1, Vector2i(26,7))
	#add_combatant(create_combatant(CombatantDatabase.combatants["tyranids_hormagaunt"], "Tyranid_7"), 1, Vector2i(28,5))
	
	
	#TURNS_UNTIL_THE_END
	 
	if current_combatant_alive != 0:
		combat_start.emit()
	
	controller.combatant_deselected.emit()


func create_combatant(definition: CombatantDefinition, override_name = ""):
	var comb = {
		"name" = definition.name,
		"max_hp" = definition.max_hp,
		"hp" = definition.max_hp,
		"class" = definition.class_t,
		"movement_class" = definition.movement_class,
		"alive" = true,
		"army" = army_list[definition.class_t],
		"skill_list" = [], #definition.skills,
		"number_attacks_max" = definition.number_attacks_max,
		"number_attacks" = definition.number_attacks_max,
		"icon" = definition.icon,
		"animation_resource" = definition.animation_resource,
		"sprite_offset" = definition.sprite_offset,
		"movement_max" = definition.movement,
		"movement" = definition.movement,
		"strength" = definition.strength,
		"psy_power" = definition.psy_power,
		"toughness" = definition.toughness,
		"armor_save" = definition.armor_save,
		"crit_chance" = definition.crit_chance,
		"weight" = definition.weight,
		"move_speed" = definition.move_speed,
		"is_transparent" = definition.is_transparent,
		"selected_path_id" = 1,
		"selected_path" = [],
		"selected_skill_id" = null,
		"selected_targets" = [],
		"next_action_type" = "None",
		"end_cd_turn" = definition.end_cd_turn,
		"arrived" = true,
		"statuses" = []
		}
	if override_name != "":
		comb.name = override_name
	if definition.skills.size() > 0:
		comb["skill_list"].append_array(definition.skills)
	return comb



func add_combatant(combatant: Dictionary, side: int, position: Vector2i):
	combatant["position"] = position
	combatant["side"] = side
	combatant["previous_position"] = position
	combatant["mouse_over"] = false
	combatants.append(combatant)
	current_combatant_alive += 1
	groups[side].append(combatant.name)
	var combatant_scene = combatant.animation_resource.instantiate()	# Instantiate the character's animation scene
	combatant_scene.name = combatant.name
	combatant_scene.y_sort_enabled = true
	var _area_2D = (combatant_scene.get_child(0)).get_child(0)
	#_area_2D.mouse_clicked.connect(controller._on_sprite_clicked)
	#_area_2D.mouse_over_it.connect(controller._on_sprite_mouse_over)
	#_area_2D.mouse_out_of_it.connect(controller._on_sprite_mouse_exited)
	add_child(combatant_scene)
	combatant_scene.position = Vector2(tile_map.map_to_local(position)) + combatant.sprite_offset
	var anim_player = combatant_scene.get_node("AnimationPlayer") # Store the reference to the AnimationPlayer for controlling animations
	var animated_sprite2D = combatant_scene.get_node("AnimatedSprite2D")
	combatant["anim_player"] = anim_player
	animated_sprite2D.play("BG_run")
	if side == 1:
		(combatant_scene.get_node("Sprite2D")).scale.x = -1
	create_hp_display(combatant_scene, combatant)
	combatant_scene.z_index = 2
	emit_signal("combatant_added", combatant)
	print("New combatant added : ", combatant.name)

func add_temporary_obstacle(tile, duration, need_sight):
	if need_sight:
		var obstacle_map = get_node("../WallMapLayer")
		obstacle_map.set_cell(tile, 5, Vector2i(0,0))
		controller.update_tile_weights_from_obstacles()
		temporary_obstacles.append([tile, turn + duration])
	else:
		var obstacle_map = get_node("../WallMapLayer")
		obstacle_map.set_cell(tile, 1, Vector2i(0,0))
		controller.update_tile_weights_from_obstacles()
		temporary_obstacles.append([tile, turn + duration])

func add_temporary_unit(tile, duration, unit_name, side):
	var new_name = unit_name + "_turn_" + str(turn) + "_born_at_" + str(tile.x) + "_" + str(tile.y)
	add_combatant(create_combatant(CombatantDatabase.combatants[unit_name], new_name), side, tile)
	temporary_units.append([new_name, turn + duration])
	
func add_temporary_trap(tile, duration, caster_name, damage, caster_strength, statuses, type):
	var new_name = "trap_of_" + caster_name + "_turn_" + str(turn) + "_born_at_" + str(tile.x) + "_" + str(tile.y)
	var obstacle_map = get_node("../TrapMapLayer")
	obstacle_map.set_cell(tile, 0, Vector2i(0,0))
	temporary_traps.append([tile, turn + duration, new_name, damage, caster_strength, statuses])
	
	
# Function to create and update HP display
func create_hp_display(combatant_scene: Node2D, combatant: Dictionary):
	# Create a TextureProgress node to act as the HP bar
	var hp_bar = ProgressBar.new()
	hp_bar.name = "HPBar"
	#hp_bar.position = Vector2(-26, -combatant_scene.get_node("Sprite2D").get_rect().size.y - 5)  # Adjust position based on sprite size
	hp_bar.anchor_left = 0.5  # Center the HP bar horizontally
	hp_bar.anchor_top = 0
	hp_bar.anchor_right = 0.5
	hp_bar.anchor_bottom = 0.1  # Adjust height based on desired bar size
	hp_bar.set_custom_minimum_size(Vector2(50, 4))  # Example size (width, height)
	# Set the range of the HP bar (0 to 300 for example)
	hp_bar.min_value = 0
	hp_bar.max_value = combatant.max_hp
	hp_bar.value = combatant.max_hp  # Set initial HP value or default to 300
	hp_bar.z_index = 10
	# Optionally set textures for a custom look
	#hp_bar.progress_texture = preload("res://textures/hp_bar_fill.png")  # Adjust path
	#hp_bar.frame_texture = preload("res://textures/hp_bar_background.png")  # Adjust path
	# Add the HP bar to the combatant scene
	hp_bar.show_percentage = false
	hp_bar.fill_mode = 0
	  # Create a new theme
	var theme = Theme.new()
	# Create a StyleBoxFlat for the background
	var background_style = StyleBoxFlat.new()
	background_style.bg_color = Color(1, 0.1, 0.1, 1)  # Dark gray
	# Assign the StyleBox to the theme's "panel" property for ProgressBar
	theme.set_stylebox("background", "ProgressBar", background_style)
	# Create a StyleBoxFlat for the fill
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0, 0.8, 0, 1)  # Red for the fill
	# Assign the StyleBox to the theme's "progress" property for ProgressBar
	theme.set_stylebox("fill", "ProgressBar", fill_style)
	# Apply the theme to the ProgressBar
	hp_bar.theme = theme
	combatant_scene.add_child(hp_bar)
	combatant["hp_bar"] = hp_bar
	
	

# Function to update HP display when HP changes
func update_hp_display(combatant: Dictionary):
	var hp_bar = combatant["hp_bar"]  # Assume 'hp_container' now refers to the ProgressBar
	var current_hp = combatant.hp
	var max_hp = combatant.max_hp
	# Ensure the ProgressBar's max value matches the max HP
	hp_bar.max_value = max_hp
	# Update the ProgressBar's value to match the current HP
	hp_bar.value = current_hp


func get_distance(attacker: Dictionary, target: Dictionary):
	var point1 = attacker.position
	var point2 = target.position
	return absi(point1.x - point2.x) + absi(point1.y - point2.y)


func attack(attacker: Dictionary, target: Dictionary, attack: String):
	var distance = get_distance(attacker, target)
	#check if attacker has melee or ranged weapon
	#i.e. check the class
	var skill = SkillDatabase.skills[attack]
	var valid = distance <= skill.max_range and distance >= skill.min_range
	if valid:
#		var prob = calc_prob(attacker.class, distance)
		var prob = calc_skill_prob(skill, distance)
		#continue if distance is correct
		#check if we hit
		var random_number = randi() % 100
		if random_number < prob:
			do_damage(attacker, target, skill)
		else:
			update_information.emit("{0} missed.\n".format([attacker.name]))
		if groups[Group.ENEMIES].size() < 1:
			combat_finish()
	else:
		update_information.emit("Target too far to attack.\n")


func Attack(attacker: Dictionary, skill: Object, target: Dictionary):
	attack(attacker, target, "attack_melee")
	
func Spell(attacker: Dictionary, skill: Object, target: Dictionary):
	attack(attacker, target, "attack_melee")


func attack_ranged(attacker: Dictionary, target: Dictionary):
	attack(attacker, target, "attack_ranged")


func basic_magic(attacker: Dictionary, target: Dictionary):
	var skill = SkillDatabase.skills["basic_magic"]
	do_damage(attacker, target, skill)

func combat_finish():
	emit_signal("combat_finished")
	pass

func do_damage(attacker: Dictionary, target: Dictionary, skill: SkillDefinition):
	var damage = randi_range(skill.min_damage, skill.max_damage)
	target.hp -= damage
	update_combatants.emit(combatants)
	update_information.emit("[color=yellow]{0}[/color] did [color=gray]{1} damage[/color] to [color=red]{2}[/color]\n".format([
		attacker.name,
		damage,
		target.name
		]))
	if target.hp <= 0:
		combatant_die(target)


func combatant_die(combatant: Dictionary):
	var	comb_id = combatants.find(combatant)
	if comb_id != -1:
		combatant.alive = false
		groups[combatant.side].erase(comb_id)
		current_combatant_alive -= 1
		update_information.emit("[color=red]{0}[/color] died.\n".format([
			combatant.name
		]
	))
	combatant.sprite.frame = 1
	combatant_died.emit(combatant)



func calc_skill_prob(skill: SkillDefinition, distance: int) -> int:
	var min_range = skill.min_range
	var max_range = skill.max_range
	if distance > max_range:
		return skill.max_prob
	if distance < min_range:
		return skill.min_prob
	if distance <= max_range and distance >= min_range:
		return 90 - 10 * (distance - 1)
	return 0


func calc_prob(attack: String, distance: int):
	if attack == "melee" or attack == "magic":
		return 90 - 10 * (distance - 1)
	if attack == "ranged":
		return 25 if distance == 1 or distance == 5 else 90

##AI

func sort_weight_array(a, b):
	if a[0] > b[0]:
		return true
	else:
		return false


func ai_process(comb : Dictionary):
	var nearest_target: Dictionary
	if comb.class == UnitClass.Melee:
		var l = INF
		for target_comb_index in groups[Group.PLAYERS]:
			var target = combatants[target_comb_index]
			var distance = get_distance(comb, target)
			if distance < l:
				l = distance
				nearest_target = target
				print(nearest_target.name)
		if get_distance(comb, nearest_target) == 1:
			attack(comb, nearest_target, "attack_melee")
			return
	await controller.ai_process(nearest_target.position)
	attack(comb, nearest_target, "attack_melee")


func ai_pick_target(weights):
	var rand_num = randf()
	var full_weight = 1.0
	for w in weights:
		var weight = w[0]
		full_weight -= weight
		if rand_num > full_weight - 0.001: #full_weight - 0.001 due to float inaccuracy
			return w[1]
