class_name Beacon extends Node2D

var is_active: bool


@onready var light: Node = $Light


func activate() -> void:
	if is_active:
		return
	
	is_active = true
	light.show()


func _on_tile_component_interacted() -> void:
	GSLogger.info("Interacted with beacon")
	activate()
