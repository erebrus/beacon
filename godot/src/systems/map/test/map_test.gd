extends Node2D

@onready var ground: GroundTileMap = %GroundTileMap
@onready var player: Node2D = %Player


var current_cell: Vector2i = Vector2i.ZERO

func _ready() -> void:
	player.position = ground.map_to_local(current_cell)
	ground.visit(current_cell)


func _input(event: InputEvent) -> void:
	if event.is_action_released("move_left"):
		_move(Vector2i.LEFT)
	elif event.is_action_released("move_right"):
		_move(Vector2i.RIGHT)
	elif event.is_action_released("move_up"):
		_move(Vector2i.UP)
	elif event.is_action_released("move_down"):
		_move(Vector2i.DOWN)
	


func _move(direction: Vector2i) -> void:
	var target := current_cell + direction
	if ground.visit(target):
		current_cell = target
		player.position = ground.map_to_local(current_cell)
