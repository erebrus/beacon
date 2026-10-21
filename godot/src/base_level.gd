class_name BaseLevel extends Node

const MOVE_TIME = .3
@export var override_game_state: GameState


var game_state:GameState

@onready var tilemap: GroundTileMap = %GroundTileMap
@onready var turn_manager: TurnManager = $TurnManager
@onready var player: CharacterBody2D = $Player


func _ready() -> void:
	_register_objects(%Trees)
	_register_objects(%Beacons)
	_register_objects(%Enemies)
	

	turn_manager.turn_order_changed.connect(func(x): GSLogger.info("Turn order: %s" % [x]))
	turn_manager.round_started.connect(func(): GSLogger.info("Round started"))
	turn_manager.round_ended.connect(func(): GSLogger.info("Round ended"))
	turn_manager.turn_started.connect(func(x): GSLogger.info("Turn started for %s" % [x.target.name]))
	turn_manager.turn_ended.connect(func(x): GSLogger.info("Turn ended for %s" % [x.target.name]))
	turn_manager.single_team_remaining.connect(func(x, _u): GSLogger.info("Battle ended with winner %s" % [x]))
	turn_manager.unit_added.connect(func(x): GSLogger.info("Added unit: %s" % [x.target.name]))
	turn_manager.unit_removed.connect(func(x): GSLogger.info("Removed unit: %s" % [x.target.name]))
	
	turn_manager.start(get_all_agents())
	

func get_all_agents() -> Array[UnitTurnComponent]:
	var ret:Array[UnitTurnComponent]
	ret.append(player.turn)
	for enemy in %Enemies.get_children():
		ret.append(enemy.turn)
	return ret

func set_state(_game_state:GameState):
	game_state = _game_state


func _register_objects(node: Node) -> void:
	if node is TileComponent:
		tilemap.register_component(node)
	else:
		for child in node.get_children():
			_register_objects(child) 
