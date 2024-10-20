# EffectData.gd
extends Resource
class_name Status

@export var name: String 		#name_of_the_status
@export var time: int			#0 for temporary effect, 1 for permanent
@export var stat: String		#name of the stat on which it has an effect
@export var effect: int			#effect on the said stat
@export var turn_total: int		#total number of turns the effect is applied
@export var turn_to_go: int		#turns to go before the end of the effect
@export var delay: int = 0		#number of turns to wait before the beginning of the effect
