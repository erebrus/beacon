extends Node2D

@export var enemies: Container

@onready var turn: UnitTurnComponent = %UnitTurnComponent


func _ready() -> void:
	turn.turn_started.connect(_on_turn_started)


func kill() -> void:
	turn.remove()
	queue_free()


func _on_turn_started() -> void:
	%AttackButton.disabled = false
	%SelfDestruct.disabled = false
	

func end_turn() -> void:
	%AttackButton.disabled = true
	%SelfDestruct.disabled = true
	turn.end_turn()

func _on_attack_1_button_pressed() -> void:
	if randf() < 0.6:
		var i = randi() % enemies.get_child_count()
		enemies.get_child(i).kill()
	end_turn()


func _on_self_destruct_pressed() -> void:
	kill()
