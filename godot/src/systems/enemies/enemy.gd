extends Node2D

@export var hp:=1.0
@export var attack_damage := 1.0
@export var max_actions := 2
@export var vision_range := 5
@export var map:GroundTileMap

@onready var tile_component: TileComponent = $TileComponent
@onready var turn: UnitTurnComponent = $UnitTurnComponent
var actions := 0
var player:Player

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

func update_vision():
	for y in range(-vision_range, vision_range + 1):
		for x in range(-vision_range, vision_range + 1):	
			var cell := Vector2i(x,y) + tile_component.cell
			var obj = map.get_object_at(cell)
			if obj and obj is Player:
				player = obj
				return 
	player = null
	
func sees_player() -> bool:
	return player != null
			
func is_next_to_player() -> bool:
	if not sees_player():
		return false
	return player.tile_component.cell.distance_to(tile_component.cell) == 1

func attack_player():
	if not is_next_to_player() or actions == 0:
		return
	GSLogger.info("%s attacking player for %d damage." % [name, attack_damage])
	player.take_damage(attack_damage)
	actions -= 1
	
func move_to(desired_cell:Vector2i):
	map.move_component(tile_component, desired_cell)
	GSLogger.info("Performing move to %s" % [desired_cell])
		
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "global_position", map.map_to_global(desired_cell), BaseLevel.MOVE_TIME)
	await tween.finished
	actions -= 1
		
func do_ai():
	while actions > 0:
		if not sees_player():
			return
		if is_next_to_player():
			attack_player()
		else:
			var path_to_player = map.get_cell_path_to(tile_component.cell, player.tile_component.cell)
			if path_to_player and path_to_player.size() > 1:
				await move_to(path_to_player[1])
			else:
				break
	




func _on_unit_turn_component_turn_started() -> void:
	GSLogger.info("%s turn" % [name])
	await get_tree().physics_frame
	actions = max_actions
	map.reset_astar([tile_component.cell])
	update_vision()
	do_ai()	
	turn.end_turn()
