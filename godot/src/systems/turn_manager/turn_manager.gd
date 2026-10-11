class_name TurnManager extends Node


signal turn_order_changed(units: Array[Array]) # Array[Array[UnitTurnComponent]]
signal unit_added(unit: UnitTurnComponent)
signal unit_removed(unit: UnitTurnComponent)

signal turn_started(unit: UnitTurnComponent)
signal turn_ended(unit: UnitTurnComponent)

signal round_started
signal round_ended
signal single_team_remaining(team: StringName, units: Array[UnitTurnComponent])

## Whether units in the same team should take their turn in parallel if they are next to each other in turn order.
@export var joint_team_turn: bool = false

## Units, in turn order.
var units: Array[UnitTurnComponent]
## Units by team.
var teams: Dictionary[StringName, Array] # Dictionary[StringName, Array[UnitTurnComponent]]
## Groups of units that take their turn together, in turn order
var turn_order: Array[Array] # Array[Array[UnitTurnComponent]]

## Units which currently have the turn.
var turn_group_units: Array[UnitTurnComponent]
## Units which have yet to take a turn in this round.
var turn_pending_in_round: Dictionary[UnitTurnComponent, bool]


## Decides turn order, handles turn to first unit.
func start(_units: Array[UnitTurnComponent]) -> void:
	teams.clear()
	
	units = _units
	for unit in units:
		_add_unit(unit)
	
	assert(teams.size() > 1)
	
	_choose_turn_order()
	_start_round()

## Add an unit when turns have already started.
## 
## If they should act before the current unit in initiative, they act just after 
## the current units ends their turn. It will take its turn in their regular turn
## order in the next round.
func add_unit(unit: UnitTurnComponent) -> void:
	units.append(unit)
	_add_unit(unit)
	
	_choose_turn_order()
	
	unit_added.emit(unit)

## Remove an unit when turns have already started.
func remove_unit(unit: UnitTurnComponent) -> void:
	if not unit in units:
		push_warning("tried to delete non-managed unit")
		return
	
	unit_removed.emit(unit)
	units.erase(unit)
	turn_pending_in_round.erase(unit)
	
	unit.turn_started.disconnect(_on_unit_turn_started)
	unit.turn_ended.disconnect(_on_unit_turn_ended)
	unit.removed.disconnect(_on_unit_removed)
	
	if teams.has(unit.team):
		teams[unit.team].erase(unit)
	
	_choose_turn_order()
	_check_single_remaining_team()
	
	if turn_group_units.has(unit):
		_on_unit_turn_ended(unit)


func _add_unit(unit: UnitTurnComponent) -> void:
	if not unit.team in teams:
		var empty: Array[UnitTurnComponent]
		teams[unit.team] = empty
	teams[unit.team].append(unit)
	turn_pending_in_round[unit] = true
	
	unit.turn_started.connect(_on_unit_turn_started.bind(unit))
	unit.turn_ended.connect(_on_unit_turn_ended.bind(unit))
	unit.removed.connect(_on_unit_removed.bind(unit))


func _choose_turn_order() -> void:
	assert(not units.is_empty())
	
	turn_order.clear()
	
	units.sort_custom(func(a: UnitTurnComponent, b: UnitTurnComponent):
		return a.initiative > b.initiative
	)
	
	var last_team: StringName
	var group: Array[UnitTurnComponent]
	
	for unit in units:
		if not joint_team_turn or unit.team != last_team or turn_order.is_empty():
			group = []
			last_team = unit.team
			turn_order.append(group)
		
		group.append(unit)
	
	_update_unit_turn_index()


func _update_unit_turn_index() -> void:
	for i in turn_order.size():
		for unit: UnitTurnComponent in turn_order[i]:
			unit.turn_index = i
	turn_order_changed.emit(turn_order)


func _check_single_remaining_team() -> bool:
	var remaining_teams := teams.keys().filter(func(team_name: StringName): 
		return not teams[team_name].is_empty()
	)
	if remaining_teams.size() == 1:
		var team_name: StringName = remaining_teams.front()
		single_team_remaining.emit(team_name, teams[team_name])
		return true
	
	return false


func _start_round() -> void:
	for unit in turn_pending_in_round:
		turn_pending_in_round[unit] = true
	
	round_started.emit()
	_start_turn(0)


func _end_round() -> void:
	round_ended.emit()
	_start_round()


func _start_turn(turn_index: int) -> void:
	turn_group_units.assign(turn_order[turn_index].filter(func(u: UnitTurnComponent): return turn_pending_in_round[u]))
	
	if turn_group_units.is_empty():
		_end_turn()
		return
	
	for unit in turn_group_units:
		if is_instance_valid(unit):
			unit.start_turn()
			turn_pending_in_round[unit] = false


func _end_turn() -> void:
	var turn_index = turn_order.size()
	for unit in turn_pending_in_round:
		if turn_pending_in_round[unit] and unit.turn_index < turn_index:
			turn_index = unit.turn_index
	
	if turn_index == turn_order.size():
		_end_round()
	else:
		_start_turn(turn_index)


func _on_unit_turn_started(unit: UnitTurnComponent) -> void:
	turn_started.emit(unit)


func _on_unit_turn_ended(unit: UnitTurnComponent) -> void:
	assert(unit in turn_group_units, "Unit should not be acting")
	
	turn_ended.emit(unit)
	
	var finished := turn_group_units.all(func(u: UnitTurnComponent): return not u.is_turn)
	
	if finished:
		_end_turn()


func _on_unit_removed(unit: UnitTurnComponent) -> void:
	remove_unit(unit)
