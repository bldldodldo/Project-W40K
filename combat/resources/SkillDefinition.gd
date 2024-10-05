extends Resource
class_name SkillDefinition

@export var name: String
@export var type: String #two types : "Attack" or "Spell"
@export var range_type: String #two types : "Range" or "List"
@export var min_range: int #used if range_type = "Range"
@export var max_range: int #used if range_type = "Range"
@export var list: Array #used if range_type = "List"
@export var min_damage: int
@export var max_damage: int
@export var min_prob: int
@export var max_prob: int
@export var icon: Texture2D
