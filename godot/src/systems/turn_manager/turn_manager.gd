class_name TurnManager extends Node


signal turn_order_changed(units: Array[Array]) # Array[Array[UnitTurnComponent]]
signal unit_added(unit: UnitTurnComponent)
signal unit_removed(unit: UnitTurnComponent)

signal turn_started(unit: UnitTurnComponent)
signal turn_ended(unit: UnitTurnComponent)

signal round_started
signal round_ended
signal ended(team: StringName, units: Array[UnitTurnComponent])

@export var join_team_turn: bool = false


var units: Array[UnitTurnComponent]
var teams: Dictionary[StringName, Array] # Dictionary[StringName, Array[UnitTurnComponent]]
var turn_order: Array[Array] # Array[Array[UnitTurnComponent]]

var current: int = 0


## Decides turn order, handles turn to first unit
func start(_units: Array[UnitTurnComponent]) -> void:
	teams.clear()
	
	units = _units
	for unit in units:
		_add_unit(unit)
	
	assert(teams.size() > 1)
	
	_choose_turn_order()
	_start_round()


func add_unit(unit: UnitTurnComponent) -> void:
	units.append(unit)
	_add_unit(unit)
	_choose_turn_order()
	unit_added.emit(unit)


func remove_unit(unit: UnitTurnComponent) -> void:
	if not unit in units:
		push_warning("tried to delete non-managed unit")
		return
	
	unit_removed.emit(unit)
	units.erase(unit)
	
	unit.turn_started.disconnect(_on_unit_turn_started)
	unit.turn_ended.disconnect(_on_unit_turn_ended)
	unit.removed.disconnect(_on_unit_removed)
	
	if teams.has(unit.team):
		teams[unit.team].erase(unit)
	
	var group: Array[UnitTurnComponent] = turn_order[unit.turn_index]
	group.erase(unit)
	if group.is_empty():
		turn_order.erase(group)
		_update_unit_turn_index()
		
		if unit.turn_index == current:
			_start_turn()
		elif unit.turn_index < current:
			current -= 1


func _add_unit(unit: UnitTurnComponent) -> void:
	if not unit.team in teams:
		var empty: Array[UnitTurnComponent]
		teams[unit.team] = empty
	teams[unit.team].append(unit)
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
		if not join_team_turn or unit.team != last_team or turn_order.is_empty():
			group = []
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
		ended.emit(team_name, teams[team_name])
		return true
	
	return false


func _start_round() -> void:
	round_started.emit()
	current = 0
	_start_turn()


func _end_round() -> void:
	round_ended.emit()
	_start_round()


func _start_turn() -> void:
	if _check_single_remaining_team():
		return
	
	if current >= turn_order.size():
		_end_round()
		return
	
	var group: Array[UnitTurnComponent] = turn_order[current]
	
	for unit in group:
		if is_instance_valid(unit):
			unit.start_turn()


func _on_unit_turn_started(unit: UnitTurnComponent) -> void:
	turn_started.emit(unit)


func _on_unit_turn_ended(unit: UnitTurnComponent) -> void:
	var group: Array[UnitTurnComponent] = turn_order[current]
	
	assert(unit in group, "Unit should not be acting")
	
	turn_ended.emit(unit)
	
	var finished := group.all(func(u: UnitTurnComponent): return not u.is_turn)
	
	if finished:
		current += 1
		_start_turn()


func _on_unit_removed(unit: UnitTurnComponent) -> void:
	remove_unit(unit)
