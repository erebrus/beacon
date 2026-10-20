extends Node2D

@export var hp:=1.0



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
