extends Node2D

const NPC = preload("test_npc.tscn")
const ENEMY = preload("test_enemy.tscn")


@onready var turn_manager: TurnManager = %TurnManager

func _ready() -> void:
	turn_manager.turn_order_changed.connect(func(x): GSLogger.info("Turn order: %s" % [x]))
	turn_manager.round_started.connect(func(): GSLogger.info("Round started"))
	turn_manager.round_ended.connect(func(): GSLogger.info("Round ended"))
	turn_manager.turn_started.connect(func(x): GSLogger.info("Turn started for %s" % [x.target.name]))
	turn_manager.turn_ended.connect(func(x): GSLogger.info("Turn ended for %s" % [x.target.name]))
	turn_manager.ended.connect(func(x, _u): GSLogger.info("Battle ended with winner %s" % [x]))
	turn_manager.unit_added.connect(func(x): GSLogger.info("Added unit: %s" % [x.target.name]))
	turn_manager.unit_removed.connect(func(x): GSLogger.info("Removed unit: %s" % [x.target.name]))
	
	turn_manager.start([%TestPlayer.turn, %TestEnemy.turn, %TestEnemy2.turn])
	
 


func _on_spawn_npc_pressed() -> void:
	var npc = NPC.instantiate()
	npc.enemies = $Enemies
	$NPCs.add_child(npc)
	turn_manager.add_unit(npc.turn)


func _on_spawn_enemy_pressed() -> void:
	var npc = ENEMY.instantiate()
	npc.enemies = $NPCs
	$Enemies.add_child(npc)
	turn_manager.add_unit(npc.turn)
