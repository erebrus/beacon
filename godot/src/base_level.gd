class_name BaseLevel extends Node

@export var override_game_state: GameState


var game_state:GameState

@onready var tilemap: GroundTileMap = %GroundTileMap


func _ready() -> void:
	_register_objects(%Trees)


func set_state(_game_state:GameState):
	game_state = _game_state


func _register_objects(node: Node) -> void:
	if node is TileComponent:
		tilemap.register_component(node)
	else:
		for child in node.get_children():
			_register_objects(child) 
