extends Resource
class_name CombatantDefinition


@export var name = ""
@export_group("Class")
@export_enum("Ultramarine", "Black_Legion", "Tyranid") var class_t = 0
@export_enum("Ground", "Flying", "Vehicle") var class_m = 0
@export_group("Stats")
@export_range(1, 2, 1, "or_greater") var max_hp = 1
@export_range(1, 3, 1, "or_greater") var movement = 3
@export_range(1, 2, 1, "or_greater") var initiative = 1
@export_range(1, 5, 1, "or_greater") var strength = 1
@export_range(1, 5, 1, "or_greater") var psy_power = 1
@export_range(1, 5, 1, "or_greater") var toughness = 1
@export_range(0, 5, 1, "or_greater") var armor_save = 0
@export_range(0, 50, 5) var crit_chance = 0
@export_group("Visual")
@export var icon: Texture2D
@export var map_sprite: Texture2D
@export var animation_resource: PackedScene #holds a scene with AnimationPlayer
@export var sprite_offset: Vector2
@export_group("Skills")
@export var skills: Array[String]
@export var number_attacks_max: int = 1 #most of units have 1. Max is 2 (only 2 phases to use attacks).
@export_group("State")
@export var statuses: Array[Status]
