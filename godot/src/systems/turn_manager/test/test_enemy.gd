extends ColorRect

@export var player: Node

@onready var turn: UnitTurnComponent = %UnitTurnComponent


func _ready() -> void:
	turn.turn_started.connect(_on_turn_started)

func kill() -> void:
	turn.remove()
	queue_free()


func _on_turn_started() -> void:
	var tween:= create_tween()
	
	tween.tween_property(self, "offset_transform_scale", Vector2(2, 2), 1)
	tween.tween_property(self, "offset_transform_scale", Vector2(1, 1), 1)
	
	await tween.finished
	
	if randf() < 0.3:
		player.kill()
	
	turn.end_turn()
