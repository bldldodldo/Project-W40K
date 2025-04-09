extends Resource
class_name SkillDefinition

@export var name: String
@export_enum("Attack", "Spell") var type: String
@export_enum("Range", "List") var range_type: String
@export var min_range: int #used if range_type = "Range"
@export var max_range: int #used if range_type = "Range"
@export var range_list: Array #used if range_type = "List"
@export var sight: bool #is true if you need a line of sight to use it (only for "Range" type of spells)
@export var hit_zone: Array #used for AoE spells
@export var number_of_target: int = 1 #used for multiple targets attacks or spells (riffle?)
@export var damage: int = 1 #between 0 and 5+
@export var prob: float = 1 #between 0 and 1
@export var armor_penetration: int = 0 #strong ! mostly 0. = brut damages -1 = 1 more dmg
@export var icon: Texture2D
@export_group("For Spells")
@export var cd: int = 0 #for SPELLS : if 1 then every turn, if more then more..
@export var statuses: Array[Status]
@export_group("Special interactions")
@export_enum("None", "To_Target", "Coord") var dash_comb: String
@export var dash_comb_coord: Vector2i
@export_enum("None", "To_Comb", "Coord") var push_target: String
@export var push_target_coord: Vector2i
@export_enum("None", "No_Sight_Needed", "Sight_Needed") var create_obstacle: String
@export var obstacle_duration: int #number of turns
@export_enum("None", "Ally", "Ennemy") var create_unit: String
@export var unit_name: String
@export var unit_duration: int
@export_enum("None", "Visible", "Invisible") var create_trap: String
@export var trap_duration: int
@export var trap_damage: int
@export var trap_statuses: Array[Status]
@export_group("Visuals")
@export var animation_name: String
@export var animation_frames_to_wait: int
