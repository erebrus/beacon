class_name Player extends CharacterBody2D

@export var map:GroundTileMap
@export var max_actions := 3
var desired_cell:Vector2i
var in_anim := false
var actions := 0

@onready var tile_component: TileComponent = $TileComponent
@onready var turn: UnitTurnComponent = $UnitTurnComponent


func _ready():
	await get_tree().process_frame
	map.register_component(tile_component)
	desired_cell = tile_component.cell
	map.visit(tile_component.cell)
	global_position = map.map_to_global(tile_component.cell)
	

func _physics_process(delta: float) -> void:
	if not in_anim and desired_cell != tile_component.cell:
		GSLogger.info("Dequeued move to %s" % [desired_cell])
		if actions == 0:
			GSLogger.info("Ignored moved. Out of actions.")
			desired_cell = tile_component.cell
			return
			
		if map.is_cell_free(desired_cell):
			_do_move()
			check_end_turn()
			return
		
		if map.can_interact(desired_cell):
			_do_interaction()
			check_end_turn()
		else:
			#can't move there. TODO give feedback
			pass
		
		desired_cell = tile_component.cell
		


func _input(event: InputEvent) -> void:
	if actions == 0:
		return
	var input_direction := Input.get_vector("move_left","move_right","move_up","move_down")
	
	var new_cell := tile_component.cell
	if Input.is_action_just_pressed("move_up"):
		new_cell += Vector2i.UP
	elif Input.is_action_just_pressed("move_down"):
		new_cell += Vector2i.DOWN
	elif Input.is_action_just_pressed("move_left"):
		new_cell += Vector2i.LEFT
	elif Input.is_action_just_pressed("move_right"):
		new_cell += Vector2i.RIGHT
	if new_cell != tile_component.cell:
		desired_cell = new_cell
		GSLogger.info("Registered move to %s" % [desired_cell])
		
		

func exclusive_cell_use() -> bool:
	return true
	
func _do_interaction() -> void:
	map.interact(desired_cell)
	actions -= 1
	GSLogger.info("Interaction. Remaining actions=%d" % [actions])

func _do_move():
	in_anim = true
	actions -= 1
	GSLogger.info("Move to %s completed. Remaining actions=%d" % [desired_cell, actions])
	map.move_component(tile_component, desired_cell)
	
	GSLogger.info("Performing move to %s" % [desired_cell])
		
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "global_position", map.map_to_global(desired_cell), BaseLevel.MOVE_TIME)
	await tween.finished
	map.visit(tile_component.cell)

	in_anim = false

func check_end_turn():
	if actions == 0:
		turn.end_turn()

func _on_unit_turn_started() -> void:
	actions = max_actions

func take_damage(dmg:float):
	GSLogger.info("Player takes damage %d" % dmg)
