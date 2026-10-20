class_name BaseLevel extends Node

@export var override_game_state: GameState


var game_state:GameState

@onready var tilemap: GroundTileMap = %GroundTileMap


func _ready() -> void:
	_register_objects(%Trees)
	_register_objects(%Beacons)
	_register_objects(%Enemies)


func set_state(_game_state:GameState):
	game_state = _game_state


func _register_objects(node: Node) -> void:
	if node is TileComponent:
		tilemap.register_component(node)
	else:
		for child in node.get_children():
			_register_objects(child) 
