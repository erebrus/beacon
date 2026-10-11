class_name UnitTurnComponent extends Node

signal turn_started
signal turn_ended
signal removed

@export var target: Node
@export var is_player: bool
@export var team: StringName
@export var initiative: int

var turn_index: int
var is_turn: bool


func _ready() -> void:
	if team.is_empty() and is_player:
		team = &"player"


func _exit_tree() -> void:
	removed.emit()


func start_turn() -> void:
	if is_turn:
		return
	
	is_turn = true
	turn_started.emit()


func end_turn() -> void:
	if not is_turn:
		return
	
	is_turn = false
	turn_ended.emit()


func remove() -> void:
	removed.emit()

func _to_string() -> String:
	return "%s:%s" % [team, target.name]
