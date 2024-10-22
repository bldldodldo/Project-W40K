extends Control

signal end_phase()

@export var combat: Combat
@export var controller: CController

const TQIcon = preload("res://ui/tq_icon.tscn")
const StatusIcon = preload("res://ui/status_icon.tscn")
	
func add_turn_queue_icon(combatant: Dictionary):
	var new_icon = TQIcon.instantiate()
	$TurnQueue/Queue.add_child(new_icon)
	new_icon.set_max_hp(combatant.max_hp)
	new_icon.set_hp(combatant.hp)
	new_icon.texture = combatant.icon
	new_icon.name = combatant.name
	new_icon.set_side(combatant.side)


func update_turn_queue(combatants: Array, turn_queue: Array):
	for c in turn_queue:
		var comb = combatants[c]
		add_turn_queue_icon(comb)


func combatant_died(combatant):
	var turn_queue_icon = $TurnQueue/Queue.find_child(combatant.name, false, false)
#	if combatant.side == 0:
#		var status = $Status.find_child(combatant.name, false, false)
#		if status != null:
#			status.queue_free()
	if turn_queue_icon != null:
		turn_queue_icon.queue_free()


func add_combatant_status(comb: Dictionary):
	if comb == {}:
		pass
	else:
		var new_status = StatusIcon.instantiate()
		$Status.add_child(new_status)
		new_status.set_icon(comb.icon)
		new_status.set_health(comb.hp, comb.max_hp)
		new_status.name = comb.name


func show_combatant_status_main(comb: Dictionary):
	if comb == {}:
		pass
	else:
		$Actions/StatusIcon.set_icon(comb.icon)
		$Actions/StatusIcon.set_health(comb.hp, comb.max_hp)
		# Call to show stats in the Information panel
		show_combatant_stats(comb)

		# Show the combatant's skill list
		set_skill_list(comb.skill_list)


func _on_end_phase_button_pressed():
	end_phase.emit()

func end_phase_ui_update():
	var turn_label = $Turn_Label  
	var phase_label = $Phase_Label
	turn_label.text = "Turn: " + str(combat.turn)
	phase_label.text = "Phase: " + str(combat.phase)

func _combatant_deselected():
	_target_selection_finished()
	set_skill_list([])
	add_combatant_status({})
	show_combatant_status_main({})

func update_information(info: String):
	# Clear previous information and display the new info
	$Actions/Information/Text.clear() 
	$Actions/Information/Text.append_text(info)

func show_combatant_stats(comb: Dictionary):
	# Clear previous information
	$Actions/Information/Text.clear()
	
	# Make sure the combatant exists
	if comb == {}:
		return

	# Format the combatant's stats
	var info = ""
	info += "HP: " + str(comb.hp) + " / " + str(comb.max_hp) + "\n"
	info += "M: " + str(comb.movement) + " / " + str(comb.movement_max) + "\n"
	info += "S: " + str(comb.strength) + "\n"
	info += "PP: " + str(comb.psy_power) + "\n"
	info += "T: " + str(comb.toughness) + "\n"
	info += "AS: " + str(comb.armor_save) + "\n"
	info += "C: " + str(comb.crit_chance) + "%\n"
	info += "NA: " + str(comb.number_attacks_max) + "\n"

	# Add status effects (if any)
	info += "Statuses:\n"
	for status in comb.statuses:
		info += "- " + status.name

	# Update the Information panel with the formatted info
	update_information(info)


func set_skill_list(skill_list: Array):
	var actions_grid_children = $Actions/ActionsPanel/ActionsGrid.get_children()
	var comb = controller.controlled_combatant
	for i in range(actions_grid_children.size()):
		var action = actions_grid_children[i] as Button
		clear_action_button_connections(action) #make sure that there was no previous connection
		if comb == null:
			action.disabled = true
			continue
		else:
			action.disabled = false
		if skill_list.size() > i:
			var skill_key = skill_list[i]
			var skill = SkillDatabase.skills[skill_key]
			action.icon = skill.icon
			action.modulate = Color(1,1,1,1)
			
			if (skill.type == "Attack" and (comb.number_attacks <= 0 or combat.phase == 1)) or (skill.type == "Spell" and (combat.phase == 3 or combat.phase == 1)):
				action.modulate = Color(1, 0, 0, 1)  # Semi-transparent red tint
			
			action.tooltip_text = skill.name
			action.pressed.connect(func():
				if combat.phase == 1:
					print("no attack nor spell in phase 1")
				else:
					if skill.type == "Attack" and comb.number_attacks <= 0:
						print("No more attack availables this turn")
					elif skill.type == "Attack" and comb.number_attacks > 0:
						comb.next_action_type = skill.type
						controller.set_selected_skill(skill_key)
						controller.begin_target_selection()
					elif skill.type == "Spell" and combat.phase == 3:
						print("no Spell in phase 3")
					elif skill.type == "Spell":
						comb.next_action_type = skill.type
						controller.set_selected_skill(skill_key)
						controller.begin_target_selection()
				
				)
		else:
			action.icon = null
			action.tooltip_text = ""
			clear_action_button_connections(action)


func clear_action_button_connections(action: Button):
	var connections = action.pressed.get_connections()
	for connection in connections:
		action.pressed.disconnect(connection.callable)


func update_combatants():
	for comb in combat.combatants:
		var status = $Status.find_child(comb.name, false, false)
		if status != null:
			status.set_health(comb.hp, comb.max_hp)


func set_movement(movement):
	$Actions/Movement.text = str(movement)


func _target_selection_finished():
	$Actions/SelectTargetMessage.visible = false


func _target_selection_started():
	$Actions/SelectTargetMessage.visible = true


func _on_controller_signal_end_phase() -> void:
	pass # Replace with function body.
