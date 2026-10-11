extends CharacterBody2D

const PLAYER_MOVE_TIME := .3
@export var map:GroundTileMap

@export 
var current_cell:Vector2i
var desired_cell:Vector2i
var in_anim := false

func _ready():
	await get_tree().process_frame
	current_cell = map.global_to_map(global_position)
	desired_cell = current_cell
	global_position = map.map_to_global(current_cell)
	map.register_object(self)
	map.visit(current_cell)


func _physics_process(delta: float) -> void:
	if not in_anim and desired_cell != current_cell:
		GSLogger.info("Dequeued move to %s" % [desired_cell])
		if map.is_cell_free(desired_cell):
			_do_move()
		elif map.has_interaction(desired_cell):
			_do_interaction()
		else:
			#can't move there. TODO give feedback
			return	
		
	
func _input(event: InputEvent) -> void:

		
	var input_direction := Input.get_vector("move_left","move_right","move_up","move_down")
	
	var new_cell := current_cell
	if Input.is_action_just_pressed("move_up"):
		new_cell += Vector2i.UP
	elif Input.is_action_just_pressed("move_down"):
		new_cell += Vector2i.DOWN
	elif Input.is_action_just_pressed("move_left"):
		new_cell += Vector2i.LEFT
	elif Input.is_action_just_pressed("move_right"):
		new_cell += Vector2i.RIGHT
	if new_cell != current_cell:
		desired_cell = new_cell
		GSLogger.info("Registered move to %s" % [desired_cell])
		
		

func exclusive_cell_use() -> bool:
	return true
	
func _do_interaction():
	pass
	
func _do_move():
	in_anim = true
	map.move_object(current_cell, desired_cell)
	current_cell = desired_cell
	
	GSLogger.info("Performing move to %s" % [desired_cell])
		
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "global_position", map.map_to_global(desired_cell), PLAYER_MOVE_TIME)
	await tween.finished
	GSLogger.info("Move to %s completed." % [desired_cell])
	map.visit(current_cell)
	in_anim = false
