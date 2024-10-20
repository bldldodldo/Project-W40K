extends Resource
class_name SkillDefinition

@export var name: String
@export var type: String #two types : "Attack" or "Spell"
@export var range_type: String #two types : "Range" or "List"
@export var min_range: int #used if range_type = "Range"
@export var max_range: int #used if range_type = "Range"
@export var range_list: Array #used if range_type = "List"
@export var hit_zone: Array #used for AoE spells
@export var number_of_target: int = 1 #used for multiple targets attacks or spells (riffle?)
@export var damage: int = 1 #between 0 and 5+
@export var prob: float = 1 #between 0 and 1
@export var armor_penetration: int = 0 #strong ! mostly 0. = brut damages -1 = 1 more dmg
@export var end_cd_turn: int = 0 #for SPELLS
@export var cd: int = 0 #for SPELLS : if 1 then every turn, if more then more..
@export var statuses: Array[Status]
@export var icon: Texture2D
