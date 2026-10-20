class_name MapTree extends Node2D

@export var hits:=3
@export var wood_per_hit := 1
@export var wood_when_chopped :=1


func chop():
	if hits:
		hits -= 1
		Events.wood_collected.emit(wood_per_hit)
		_check_full_chop()
		_update_sprite()
	else:
		GSLogger.warn("Chopped tree interacted with")

func _update_sprite():
	#TODO
	pass

func _check_full_chop():
	if hits == 0:
		Events.wood_collected.emit(wood_when_chopped)
		#TODO animation
		queue_free()

func _on_tile_component_interacted() -> void:
	GSLogger.info("Interacted with tree")
	chop()
