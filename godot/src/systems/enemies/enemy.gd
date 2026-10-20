extends Node2D

@export var hp:=1.0


@onready var turn: UnitTurnComponent = $UnitTurnComponent

func take_damage():
	if hp:
		GSLogger.info("Enemy takes damage.")
		hp -= 1
		if hp == 0:
			do_death()

func do_death():
	GSLogger.info("Enemy dies.")
	queue_free()
	
func _on_tile_component_interacted() -> void:
	take_damage()


func _on_unit_turn_component_turn_started() -> void:
	GSLogger.info("%s turn" % [name])
	await get_tree().physics_frame
	turn.end_turn()
