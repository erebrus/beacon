extends Node2D

@export var enemy1: Node
@export var enemy2: Node

@onready var turn: UnitTurnComponent = %UnitTurnComponent


func _ready() -> void:
	turn.turn_started.connect(_on_turn_started)


func kill() -> void:
	turn.remove()
	queue_free()


func _on_turn_started() -> void:
	%Attack1Button.disabled = false
	%Attack2Button.disabled = false
	%SelfDestruct.disabled = false
	

func end_turn() -> void:
	%Attack1Button.disabled = true
	%Attack2Button.disabled = true
	%SelfDestruct.disabled = true
	turn.end_turn()

func _on_attack_1_button_pressed() -> void:
	if randf() < 0.6:
		enemy1.kill()
	end_turn()


func _on_attack_2_button_pressed() -> void:
	if randf() < 0.6:
		enemy2.kill()
	end_turn()


func _on_self_destruct_pressed() -> void:
	kill()
